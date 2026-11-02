import "dotenv/config";
import crypto from "node:crypto";
import express from "express";
import multer from "multer";
import cors from "cors";
import { PDFParse } from "pdf-parse";

const PORT = Number(process.env.PORT ?? 3000);
// MedGemma runs on this machine through Ollama, for free.
const OLLAMA_URL = process.env.OLLAMA_URL ?? "http://localhost:11434";
const OLLAMA_MODEL = process.env.OLLAMA_MODEL ?? "medgemma1.5:4b-it-q8_0";
const ALLOWED_ORIGINS = (process.env.ALLOWED_ORIGINS ?? "http://localhost:8765")
  .split(",")
  .map((o) => o.trim());

const MAX_FILES = 5;
const MAX_FILE_BYTES = 20 * 1024 * 1024;
const IMAGE_TYPES = new Set(["image/png", "image/jpeg"]);
const PDF_TYPE = "application/pdf";
const MAX_PDF_PAGES = 5;

class AnalysisError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

const SYSTEM_PROMPT = `You help patients using the SmartLAB app understand their medical tests in plain language. The input is a lab report (PDF or photo), values the patient typed in, a medical image such as an X-ray, or a combination.

For lab results: extract every test value with its unit and reference range. Put only the number in value and the unit in unit.Use the range printed on the report; for values the patient typed in, use the standard adult reference range and say so in the explanation. Mark a value "low" or "high" only when it falls outside that range; use "unknown" when no range applies. Never invent values that were not provided. Give each value a one- or two-sentence explanation of what it measures and what this result means.

For medical images: describe what is visible in plain language, leave values empty, and be clear that only a radiologist or doctor can make a diagnosis.

Your explanation is educational, not a diagnosis. Point out abnormal results, say what they are commonly associated with, and recommend seeing a doctor whenever something is abnormal. Recommendations should be practical: follow-up with a doctor, retesting, and lifestyle notes tied to specific results.

Set riskLevel to "low" or "normal" when everything is in range, "moderate" when some values are mildly outside the range, and "high" when values are far outside the range or the combination warrants prompt medical attention. Set category to the kind of test.

Build the dietary plan from these specific results: 3 to 5 categories, each tied to a result in its reason (for example "Based on your low hemoglobin"), with 3 or 4 foods and a short benefit for each. Include a "limit" category for foods to reduce when relevant. When every result is normal, give general healthy-eating categories and say the results are in range. The pro tip is one practical, specific tip.

Set isMedicalDocument to true for lab reports, typed-in test values, and medical images such as X-rays, CT, MRI, and ultrasound. If the input is not a medical test or medical image, set isMedicalDocument to false and leave the other fields empty.`;

const ANALYSIS_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: [
    "isMedicalDocument", "category", "summary", "interpretation", "insights",
    "recommendations", "riskLevel", "values", "dietary",
  ],
  properties: {
    isMedicalDocument: { type: "boolean" },
    category: { type: "string", enum: ["blood", "hormone", "organ", "urine", "imaging", "other"] },
    summary: { type: "string" },
    interpretation: { type: "string" },
    insights: { type: "array", items: { type: "string" } },
    recommendations: { type: "array", items: { type: "string" } },
    riskLevel: { type: "string", enum: ["low", "normal", "moderate", "high"] },
    values: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["name", "value", "unit", "referenceRange", "status", "explanation"],
        properties: {
          name: { type: "string" },
          value: { type: "string" },
          unit: { type: "string" },
          referenceRange: { type: "string" },
          status: { type: "string", enum: ["low", "normal", "high", "unknown"] },
          explanation: { type: "string" },
        },
      },
    },
    dietary: {
      type: "object",
      additionalProperties: false,
      required: ["categories", "proTip"],
      properties: {
        categories: {
          type: "array",
          items: {
            type: "object",
            additionalProperties: false,
            required: ["title", "kind", "reason", "foods"],
            properties: {
              title: { type: "string" },
              kind: {
                type: "string",
                enum: ["iron", "protein", "omega3", "fiber", "hydration", "calcium", "vitamins", "limit", "other"],
              },
              reason: { type: "string" },
              foods: {
                type: "array",
                items: {
                  type: "object",
                  additionalProperties: false,
                  required: ["name", "benefit"],
                  properties: {
                    name: { type: "string" },
                    benefit: { type: "string" },
                  },
                },
              },
            },
          },
        },
        proTip: { type: "string" },
      },
    },
  },
};

function parseTypedValues(raw) {
  if (!raw) return [];
  try {
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];
    return parsed
      .map((v) => ({
        name: String(v?.name ?? "").trim(),
        value: String(v?.value ?? "").trim(),
        unit: String(v?.unit ?? "").trim(),
      }))
      .filter((v) => v.name && v.value)
      .slice(0, 100);
  } catch {
    return [];
  }
}

// MedGemma can't read PDFs, so send their text, or page images when the PDF is a scan.
async function readPdfForOllama(buffer) {
  const parser = new PDFParse({ data: buffer });
  try {
    const text = (await parser.getText({ first: MAX_PDF_PAGES })).text.replace(/-- \d+ of \d+ --/g, "").trim();
    if (text.length >= 20) {
      return { text, images: [] };
    }
    const { pages } = await parser.getScreenshot({ first: MAX_PDF_PAGES, scale: 2, imageDataUrl: false });
    return { text: "", images: pages.map((p) => Buffer.from(p.data).toString("base64")) };
  } finally {
    await parser.destroy();
  }
}

async function analyzeWithOllama(files, patientText) {
  const images = [];
  const reportTexts = [];
  for (const file of files) {
    if (file.mimetype === PDF_TYPE) {
      const pdf = await readPdfForOllama(file.buffer);
      if (pdf.text) {
        reportTexts.push(`Lab report text (include every test listed, one entry per line):\n${pdf.text}`);
      }
      images.push(...pdf.images);
    } else {
      images.push(file.buffer.toString("base64"));
    }
  }

  let response;
  try {
    response = await fetch(`${OLLAMA_URL}/api/chat`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        model: OLLAMA_MODEL,
        stream: false,
        format: ANALYSIS_SCHEMA,
        options: { temperature: 0, num_ctx: 16384 },
        messages: [
          { role: "system", content: SYSTEM_PROMPT },
          {
            role: "user",
            content: [...reportTexts, patientText, "Return the analysis as JSON."].join("\n\n"),
            images,
          },
        ],
      }),
    });
  } catch {
    console.error(`Could not reach Ollama at ${OLLAMA_URL}. Is it running?`);
    throw new AnalysisError(503, "The AI service is not running.");
  }

  if (!response.ok) {
    console.error(`Ollama error ${response.status}:`, await response.text());
    if (response.status === 404) {
      console.error(`Model missing. Run: ollama pull ${OLLAMA_MODEL}`);
    }
    throw new AnalysisError(502, "The AI service returned an error.");
  }

  const data = await response.json();
  if (data.done_reason === "length") {
    throw new AnalysisError(502, "The analysis was cut off. Try fewer or smaller files.");
  }
  try {
    return JSON.parse(data.message.content);
  } catch {
    console.error("Ollama returned invalid JSON:", data.message?.content);
    throw new AnalysisError(502, "The AI returned an unreadable analysis. Try again.");
  }
}

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_FILE_BYTES, files: MAX_FILES },
  fileFilter: (_req, file, cb) => {
    cb(null, file.mimetype === PDF_TYPE || IMAGE_TYPES.has(file.mimetype));
  },
});

const app = express();
app.use(cors({ origin: ALLOWED_ORIGINS }));

app.get("/health", (_req, res) => res.json({ ok: true, model: OLLAMA_MODEL }));

app.post("/api/analysis/analyze-files", upload.array("files", MAX_FILES), async (req, res) => {
  const files = req.files ?? [];
  const typedValues = parseTypedValues(req.body.values);
  if (files.length === 0 && typedValues.length === 0) {
    return res.status(400).json({ error: "Attach a report (PDF, PNG, JPEG) or enter at least one test value." });
  }

  const testName = String(req.body.testName ?? "").trim();
  const testEntryId = String(req.body.testEntryId ?? "");
  const description = String(req.body.description ?? "").trim().slice(0, 2000);

  const patientText = [
    `Test name entered by the patient: ${testName || "(not given)"}`,
    description && `Patient's notes: ${description}`,
    typedValues.length > 0 &&
      `Values typed in by the patient (analyze only these; do not add any others):\n${typedValues.map((v) => `- ${v.name}: ${v.value} ${v.unit}`.trim()).join("\n")}`,
  ]
    .filter(Boolean)
    .join("\n\n");

  try {
    const analysis = await analyzeWithOllama(files, patientText);

    if (!analysis.isMedicalDocument) {
      return res.status(422).json({ error: "This doesn't look like a lab report or medical image." });
    }

    res.json({
      id: crypto.randomUUID(),
      testEntryId,
      category: analysis.category,
      summary: analysis.summary,
      interpretation: analysis.interpretation,
      insights: analysis.insights,
      recommendations: analysis.recommendations,
      riskLevel: analysis.riskLevel,
      values: analysis.values,
      dietary: analysis.dietary,
      createdAt: new Date().toISOString(),
    });
  } catch (error) {
    if (error instanceof AnalysisError) {
      return res.status(error.status).json({ error: error.message });
    }
    console.error(error);
    res.status(500).json({ error: "Unexpected server error." });
  }
});

app.use((err, _req, res, _next) => {
  if (err instanceof multer.MulterError) {
    return res.status(400).json({ error: `Upload rejected: ${err.message}` });
  }
  console.error(err);
  res.status(500).json({ error: "Unexpected server error." });
});

app.listen(PORT, () => {
  console.log(`SmartLAB analysis server on http://localhost:${PORT} using ${OLLAMA_MODEL}`);
});
