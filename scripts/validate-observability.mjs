import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const rootDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = relativePath => fs.readFileSync(path.join(rootDir, relativePath), "utf8");
const observability = read("terraform/production/observability.tf");
const main = read("terraform/production/main.tf");
const variables = read("terraform/production/variables.tf");
const outputs = read("terraform/production/outputs.tf");
const monitoringDocs = read("docs/observability-monitoring.md");
const readme = read("README.md");

const metrics = [
  "cpu_percent",
  "physical_data_read_percent",
  "log_write_percent",
  "workers_percent",
  "sessions_percent",
  "storage_percent"
];

for (const metric of metrics) {
  assert.ok(observability.includes(`metric_name = "${metric}"`), `missing alert for ${metric}`);
  assert.ok(variables.includes(`"${metric}"`), `missing configurable threshold for ${metric}`);
}

assert.match(observability, /resource "azurerm_monitor_metric_alert" "pool_saturation"/);
assert.match(observability, /for_each = local\.pool_metric_alerts/);
assert.match(observability, /resource "azurerm_application_insights_workbook" "sql_operations"/);
assert.match(observability, /resourceType\s+= "microsoft\.operationalinsights\/workspaces"/);
assert.match(outputs, /output "sql_operations_workbook_id"/);
assert.match(outputs, /output "pool_saturation_alert_ids"/);
assert.match(monitoringDocs, /Grafana and Prometheus integration and dashboard setup are \*\*not part of this[\s\S]*Terraform deployment/);
assert.match(readme, /Grafana and Prometheus[\s\S]*separate future task/);
assert.equal((main.match(/setintersection\(/g) ?? []).length, 4, "diagnostic category filters must cover server, master, pools and databases");

console.log("Observability coverage checks passed.");
