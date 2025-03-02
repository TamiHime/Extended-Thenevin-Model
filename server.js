const express = require("express");
const { exec } = require("child_process");
const cors = require("cors");

const app = express();
app.use(express.json());
app.use(cors());

app.post("/api/optimize", (req, res) => {
  const { R0, R1, C1, R2, C2 } = req.body;

  // Construct Octave command
  const command = `octave --silent --eval "optimize_RC(${R0}, ${R1}, ${C1}, ${R2}, ${C2})"`;

  exec(command, (error, stdout) => {
    if (error) {
      return res.status(500).json({ error: "Octave execution failed" });
    }

    const match = stdout.match(/R0: ([\d.]+), R1: ([\d.]+), C1: ([\d.]+), R2: ([\d.]+), C2: ([\d.]+)/);
    if (!match) {
      return res.status(500).json({ error: "Failed to parse output" });
    }

    res.json({
      R0: parseFloat(match[1]),
      R1: parseFloat(match[2]),
      C1: parseFloat(match[3]),
      R2: parseFloat(match[4]),
      C2: parseFloat(match[5]),
    });
  });
});

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
