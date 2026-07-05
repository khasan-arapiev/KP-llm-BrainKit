const fs = require("fs");
const p = process.argv[2], dir = process.argv[3];
try {
  const d = JSON.parse(fs.readFileSync(p, "utf8"));
  if (typeof d !== "object" || d === null) process.exit(1);
  d.projects = d.projects || {};
  d.projects[dir] = d.projects[dir] || {};
  if (d.projects[dir].hasTrustDialogAccepted !== true) {
    d.projects[dir].hasTrustDialogAccepted = true;
    fs.writeFileSync(p + ".kp-tmp", JSON.stringify(d, null, 2));
    fs.renameSync(p + ".kp-tmp", p);
  }
} catch (e) { process.exit(1); }
