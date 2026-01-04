export function formatNumber(n) {
  if (!Number.isFinite(n)) return "0";
  if (n < 1000) return String(Math.floor(n));

  const units = ["K", "M", "B", "T"];
  let value = n;
  let unitIndex = -1;

  while (value >= 1000 && unitIndex < units.length - 1) {
    value /= 1000;
    unitIndex += 1;
  }

  const rounded = value >= 100 ? value.toFixed(0) : value >= 10 ? value.toFixed(1) : value.toFixed(2);
  return `${rounded}${units[unitIndex]}`;
}


