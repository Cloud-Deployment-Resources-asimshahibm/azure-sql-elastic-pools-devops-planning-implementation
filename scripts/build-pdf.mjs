import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(scriptDir, "..");
const sourcePaths = [
  "docs/production-readiness-plan.md",
  "docs/environment-inputs.md",
  "docs/production-deployment-runbook.md"
].map(filePath => path.join(rootDir, filePath));
const outputPath = path.join(rootDir, "docs", "Azure-SQL-Elastic-Pool-Operations-Runbook.pdf");
const pageWidth = 612;
const pageHeight = 792;
const margin = 52;
const bottom = 58;
const pages = [];
let page = [];
let y = pageHeight - margin;

function ascii(text) {
  return text
    .replace(/!\[([^\]]*)\]\([^)]+\)/g, "$1")
    .replace(/\[([^\]]+)\]\([^)]+\)/g, "$1")
    .replace(/\*\*(.*?)\*\*/g, "$1")
    .replace(/`([^`]+)`/g, "$1")
    .replace(/[“”]/g, '"')
    .replace(/[‘’]/g, "'")
    .replace(/[–—]/g, "-")
    .replace(/→/g, "->")
    .replace(/≤/g, "<=")
    .replace(/≥/g, ">=")
    .replace(/≠/g, "!=")
    .replace(/·/g, "*")
    .replace(/[^\x20-\x7E]/g, "");
}

function escapePdf(text) {
  return ascii(text).replace(/\\/g, "\\\\").replace(/\(/g, "\\(").replace(/\)/g, "\\)");
}

function addPage() {
  pages.push(page);
  page = [];
  y = pageHeight - margin;
}

function ensure(height) {
  if (y - height < bottom) addPage();
}

function writeLine(text, { font = "F1", size = 9.4, indent = 0, gapAfter = 3, color = "0 0 0" } = {}) {
  ensure(size + gapAfter + 1);
  page.push(
    `BT ${color} rg /${font} ${size} Tf 1 0 0 1 ${margin + indent} ${y} Tm (${escapePdf(text)}) Tj ET`
  );
  y -= size + gapAfter;
}

function wrap(text, maxChars) {
  const words = ascii(text).trim().split(/\s+/).flatMap(word => {
    if (word.length <= maxChars) return [word];
    const segments = [];
    for (let index = 0; index < word.length; index += maxChars) {
      segments.push(word.slice(index, index + maxChars));
    }
    return segments;
  });
  const lines = [];
  let line = "";
  for (const word of words) {
    if (!word) continue;
    if (!line) {
      line = word;
    } else if (`${line} ${word}`.length <= maxChars) {
      line += ` ${word}`;
    } else {
      lines.push(line);
      line = word;
    }
  }
  if (line) lines.push(line);
  return lines;
}

function paragraph(text, options = {}) {
  const { font = "F1", size = 9.4, indent = 0, maxChars = 96, gapAfter = 3, color } = options;
  for (const line of wrap(text, maxChars)) {
    writeLine(line, { font, size, indent, gapAfter, color });
  }
}

function drawArchitecture() {
  page = [];
  y = pageHeight - 74;
  writeLine("PRODUCTION REFERENCE ARCHITECTURE", { font: "F2", size: 17, gapAfter: 14, color: "0.07 0.22 0.39" });
  const box = (x, top, width, height, lines, fill = "0.91 0.95 0.98") => {
    page.push(`${fill} rg ${x} ${top - height} ${width} ${height} re f`);
    page.push("0.25 0.39 0.52 RG 0.8 w");
    page.push(`${x} ${top - height} ${width} ${height} re S`);
    let textY = top - 18;
    for (const line of lines) {
      page.push(`BT 0.08 0.16 0.24 rg /F2 9 Tf 1 0 0 1 ${x + 8} ${textY} Tm (${escapePdf(line)}) Tj ET`);
      textY -= 13;
    }
  };
  const arrow = (x1, y1, x2, y2) => {
    page.push(`0.25 0.39 0.52 RG 1.2 w ${x1} ${y1} m ${x2} ${y2} l S`);
    page.push(`${x2} ${y2} m ${x2 - 5} ${y2 + 3} l ${x2 - 5} ${y2 - 3} l h f`);
  };
  box(58, 646, 148, 72, ["APPLICATIONS", "Private subnets", "Private DNS + TLS"]);
  box(238, 646, 164, 72, ["AZURE SQL DATABASE", "Entra-only auth", "Public access off"]);
  box(434, 646, 122, 72, ["ELASTIC POOLS", "Workload-aligned", "Pooled databases"]);
  arrow(206, 610, 238, 610);
  arrow(402, 610, 434, 610);
  box(62, 500, 172, 86, ["AZURE MONITOR", "Pool + DB metrics", "CPU / IO / workers", "Storage / availability"], "0.91 0.97 0.92");
  box(246, 500, 164, 86, ["LOG ANALYTICS", "Server + pool + DB logs", "SQL auditing", "Approved retention"], "0.91 0.97 0.92");
  box(424, 500, 132, 86, ["DELIVERY + OPS", "Azure DevOps OIDC", "Private TF state", "Approved apply"], "0.99 0.95 0.87");
  arrow(320, 574, 148, 500);
  arrow(320, 574, 328, 500);
  page.push("0.25 0.39 0.52 RG 1.1 w 234 478 m 234 520 l 490 520 l 490 500 l S");
  page.push("490 500 m 487 506 l 493 506 l h f");
  arrow(410, 457, 424, 457);
  box(190, 338, 236, 72, ["RECOVERY REGION", "Geo-replicated databases / pools", "Tested failover + RPO / RTO"], "0.97 0.92 0.92");
  arrow(496, 500, 426, 410);
  page.push("0.35 0.35 0.35 RG 0.8 w [3 3] 0 d 402 574 m 402 430 l 426 410 l S [] 0 d");
  y = 280;
  paragraph("Applications reach the Entra-only SQL server over Private Link and private DNS. Terraform is delivered by Azure DevOps workload identity; its private Blob state backend uses lease locking. Azure Monitor metrics, server auditing, and resource diagnostics feed Log Analytics and staffed alerts. A separately tested recovery region supports the approved continuity plan.", { maxChars: 98, size: 9.2, gapAfter: 5 });
  paragraph("Reference only, not a deployed environment. Confirm topology, regional redundancy, product support, SKU, cost, and RPO/RTO with service owners.", { font: "F2", size: 8.4, maxChars: 105, gapAfter: 4, color: "0.25 0.25 0.25" });
}

function renderMarkdown(markdown) {
  const lines = markdown.split(/\r?\n/);
  let inCode = false;
  let codeLines = [];
  let tableRows = [];

  const flushTable = () => {
    if (!tableRows.length) return;
    for (const row of tableRows) {
      if (/^\|[\s|:-]+\|$/.test(row.replace(/\s/g, ""))) continue;
      const cells = row.split("|").slice(1, -1).map(cell => cell.trim()).filter(Boolean);
      if (cells.length) paragraph(cells.join("  |  "), { font: "F2", size: 7.8, maxChars: 105, indent: 4, gapAfter: 2 });
    }
    y -= 4;
    tableRows = [];
  };

  for (const raw of lines) {
    const line = raw.trim();
    if (line.startsWith("```")) {
      flushTable();
      if (inCode) {
        for (const codeLine of codeLines) {
          paragraph(codeLine || " ", { font: "F3", size: 7.2, maxChars: 110, indent: 10, gapAfter: 1, color: "0.12 0.22 0.31" });
        }
        y -= 5;
        codeLines = [];
        inCode = false;
      } else {
        inCode = true;
      }
      continue;
    }
    if (inCode) {
      codeLines.push(line);
      continue;
    }
    if (/^\|/.test(line)) {
      tableRows.push(line);
      continue;
    }
    flushTable();
    if (!line || /^---+$/.test(line)) {
      y -= line ? 3 : 2;
      continue;
    }
    const heading = line.match(/^(#{1,3})\s+(.+)$/);
    if (heading) {
      const level = heading[1].length;
      const size = level === 1 ? 19 : level === 2 ? 13.5 : 10.5;
      ensure(size + 15);
      y -= level === 1 ? 5 : 3;
      paragraph(heading[2], {
        font: "F2",
        size,
        maxChars: level === 1 ? 58 : level === 2 ? 82 : 100,
        gapAfter: level === 1 ? 8 : 5,
        color: level <= 2 ? "0.07 0.22 0.39" : "0.13 0.30 0.45"
      });
      continue;
    }
    if (line.startsWith(">")) {
      paragraph(line.replace(/^>\s?/, ""), { font: "F2", size: 9, maxChars: 96, indent: 12, gapAfter: 3, color: "0.28 0.28 0.28" });
      continue;
    }
    const bullet = line.match(/^[-*]\s+(.+)$/);
    if (bullet) {
      paragraph(`- ${bullet[1]}`, { size: 9, maxChars: 99, indent: 8, gapAfter: 2 });
      continue;
    }
    const ordered = line.match(/^(\d+)\.\s+(.+)$/);
    if (ordered) {
      paragraph(`${ordered[1]}. ${ordered[2]}`, { size: 9, maxChars: 99, indent: 6, gapAfter: 2 });
      continue;
    }
    paragraph(line, { size: 9.1, maxChars: 102, gapAfter: 3 });
  }
  flushTable();
  if (page.length) pages.push(page);
}

function pdfObject(content) {
  return `<< ${content} >>`;
}

const markdown = sourcePaths
  .map(sourcePath => fs.readFileSync(sourcePath, "utf8"))
  .join("\n\n---\n\n");
pages.push([
  "0.07 0.22 0.39 rg 0 0 612 792 re f",
  "BT 1 1 1 rg /F2 25 Tf 1 0 0 1 64 625 Tm (Azure SQL Elastic Pools) Tj ET",
  "BT 1 1 1 rg /F2 22 Tf 1 0 0 1 64 590 Tm (DevOps Planning & Implementation) Tj ET",
  "BT 0.83 0.91 0.97 rg /F1 13 Tf 1 0 0 1 66 540 Tm (Readiness plan, environment worksheet, Terraform,) Tj ET",
  "BT 0.83 0.91 0.97 rg /F1 13 Tf 1 0 0 1 66 519 Tm (Azure DevOps, operations, and recovery) Tj ET",
  "0.22 0.48 0.67 rg 64 460 484 2 re f",
  "BT 1 1 1 rg /F2 12 Tf 1 0 0 1 66 425 Tm (Reference scale: 10+ elastic pools / 100+ databases) Tj ET",
  "BT 0.83 0.91 0.97 rg /F1 10 Tf 1 0 0 1 66 390 Tm (Planning template only - no Azure subscription or deployment included.) Tj ET",
  "BT 0.83 0.91 0.97 rg /F1 9 Tf 1 0 0 1 66 62 Tm (Azure SQL Elastic Pools - DevOps Planning & Implementation) Tj ET"
]);
drawArchitecture();
renderMarkdown(markdown);

const objects = [];
const addObject = value => {
  objects.push(value);
  return objects.length;
};

const catalogId = addObject("");
const pagesId = addObject("");
const fontRegularId = addObject(pdfObject("/Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding"));
const fontBoldId = addObject(pdfObject("/Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding"));
const fontMonoId = addObject(pdfObject("/Type /Font /Subtype /Type1 /BaseFont /Courier /Encoding /WinAnsiEncoding"));
const pageIds = [];

for (const [index, pageContent] of pages.entries()) {
  const isCover = index === 0;
  const commands = [...pageContent];
  if (!isCover) {
    commands.push(`BT 0.35 0.35 0.35 rg /F1 8 Tf 1 0 0 1 ${margin} 30 Tm (Azure SQL Elastic Pools - DevOps Planning and Implementation) Tj ET`);
    commands.push(`BT 0.35 0.35 0.35 rg /F1 8 Tf 1 0 0 1 540 30 Tm (${index + 1}) Tj ET`);
  }
  const stream = commands.join("\n");
  const contentId = addObject(`<< /Length ${Buffer.byteLength(stream, "latin1")} >>\nstream\n${stream}\nendstream`);
  const pageId = addObject(
    `<< /Type /Page /Parent ${pagesId} 0 R /MediaBox [0 0 ${pageWidth} ${pageHeight}] /Resources << /Font << /F1 ${fontRegularId} 0 R /F2 ${fontBoldId} 0 R /F3 ${fontMonoId} 0 R >> >> /Contents ${contentId} 0 R >>`
  );
  pageIds.push(pageId);
}

objects[catalogId - 1] = pdfObject(`/Type /Catalog /Pages ${pagesId} 0 R`);
objects[pagesId - 1] = pdfObject(`/Type /Pages /Kids [${pageIds.map(id => `${id} 0 R`).join(" ")}] /Count ${pageIds.length}`);

let pdf = "%PDF-1.4\n%\xE2\xE3\xCF\xD3\n";
const offsets = [0];
for (let i = 0; i < objects.length; i++) {
  offsets.push(Buffer.byteLength(pdf, "latin1"));
  pdf += `${i + 1} 0 obj\n${objects[i]}\nendobj\n`;
}
const xrefOffset = Buffer.byteLength(pdf, "latin1");
pdf += `xref\n0 ${objects.length + 1}\n0000000000 65535 f \n`;
for (const offset of offsets.slice(1)) {
  pdf += `${String(offset).padStart(10, "0")} 00000 n \n`;
}
pdf += `trailer\n<< /Size ${objects.length + 1} /Root ${catalogId} 0 R >>\nstartxref\n${xrefOffset}\n%%EOF\n`;

fs.writeFileSync(outputPath, Buffer.from(pdf, "latin1"));
console.log(`Created ${path.relative(rootDir, outputPath)} (${pages.length} pages).`);
