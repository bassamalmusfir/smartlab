import "dotenv/config";
import crypto from "node:crypto";
import express from "express";
import multer from "multer";
import cors from "cors";
import Anthropic from "@anthropic-ai/sdk";

const PORT = Number(process.env.PORT ?? 3000);
const MODEL = process.env.CLAUDE_MODEL ?? "claude-opus-5-5";
const ALLOWED_ORIGINS = (process.env.ALLOWED_ORIGINS ?? "http://localhost:8765")
  .split(",")
  .map((o) => o.trim());

const MAX_FILES = 5;
const MAX_FILE_BYTES = 20 * 1024 * 1024;
const IMAGE_TYPES = new Set(["image/png", "image/jpeg"]);
const PDF_TYPE = "application/pdf";

const client = new Anthropic();

const SYSTEM_PROMPT = `You read medical laboratory reports (blood tests, urine tests, etc.) for patients using the SmartLAB app and explain them in plain language.

Extract every test value printed on the report with its unit and the reference range printed next to it. Mark a value "low" or "high" only when it falls outside the report's own reference range; use "unknown" when the report gives no range. Do not invent values that are not on the report.

Then explain what the results mean for a non-medical reader. Your explanation is educational, not a diagnosis: point out values outside the range, say what they are commonly associated with, and recommend seeing a doctor whenever something is abnormal. Recommendations should be practical (follow-up with a doctor, retesting, general diet or lifestyle notes tied to specific results).

Set riskLevel to "low" or "normal" when everything is in range, "moderate" when some values are mildly outside the range, and "high" when values are far outside the range or the combination warrants prompt medical attention.

If the files are not a lab report, set isLabReport to false and leave the other fields empty.`;

const ANALYSIS_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["isLabReport", "summary", "interpretation", "insights", "recommendations", "riskLevel", "values"],
  properties: {
    isLabReport: { type: "boolean" },
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
        required: ["name", "value", "unit", "referenceRange", "status"],
        properties: {
          name: { type: "string" },
          value: { type: "string" },
          unit: { type: "string" },
          referenceRange: { type: "string" },
          status: { type: "string", enum: ["low", "normal", "high", "unknown"] },
        },
      },
    },
  },
};

function toContentBlock(file) {
  const data = file.buffer.toString("base64");
  if (file.mimetype === PDF_TYPE) {
    return { type: "document", source: { type: "base64", media_type: PDF_TYPE, data } };
  }
  return { type: "image", source: { type: "base64", media_type: file.mimetype, data } };
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

app.get("/health", (_req, res) => res.json({ ok: true, model: MODEL }));

app.post("/api/analysis/analyze-files", upload.array("files", MAX_FILES), async (req, res) => {
  const files = req.files ?? [];
  if (files.length === 0) {
    return res.status(400).json({ error: "Attach at least one PDF, PNG or JPEG file." });
  }

  const testName = String(req.body.testName ?? "").trim();
  const testEntryId = String(req.body.testEntryId ?? "");

  try {
    const response = await client.beta.messages.create({
      model: MODEL,
      max_tokens: 16000,
      betas: ["server-side-fallback-2026-07-01"],
      fallbacks: "default",
      output_config: {
        effort: "medium",
        format: { type: "json_schema", schema: ANALYSIS_SCHEMA },
      },
      system: SYSTEM_PROMPT,
      messages: [
        {
          role: "user",
          content: [
            ...files.map(toContentBlock),
            { type: "text", text: `Test name entered by the patient: ${testName || "(not given)"}` },
          ],
        },
      ],
    });

    if (response.stop_reason === "refusal") {
      return res.status(422).json({ error: "The AI declined to analyze these files." });
    }
    if (response.stop_reason === "max_tokens") {
      return res.status(502).json({ error: "The analysis was cut off. Try fewer or smaller files." });
    }

    const text = response.content.find((b) => b.type === "text")?.text;
    if (!text) {
      return res.status(502).json({ error: "The AI returned no analysis." });
    }
    const analysis = JSON.parse(text);

    if (!analysis.isLabReport) {
      return res.status(422).json({ error: "These files don't look like a lab report." });
    }

    res.json({
      id: crypto.randomUUID(),
      testEntryId,
      summary: analysis.summary,
      interpretation: analysis.interpretation,
      insights: analysis.insights,
      recommendations: analysis.recommendations,
      riskLevel: analysis.riskLevel,
      values: analysis.values,
      createdAt: new Date().toISOString(),
    });
  } catch (error) {
    if (error instanceof Anthropic.AuthenticationError) {
      console.error("Anthropic API key is missing or invalid.");
      return res.status(500).json({ error: "Server AI key is not configured correctly." });
    }
    if (error instanceof Anthropic.RateLimitError) {
      return res.status(429).json({ error: "Too many requests to the AI. Try again in a minute." });
    }
    if (error instanceof Anthropic.APIError) {
      console.error(`Anthropic API error ${error.status}:`, error.message);
      return res.status(502).json({ error: "The AI service returned an error." });
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
  console.log(`SmartLAB analysis server on http://localhost:${PORT} using ${MODEL}`);
});
