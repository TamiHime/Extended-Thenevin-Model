const express = require("express");
const { exec } = require("child_process");
const cors = require("cors");

const app = express();
app.use(express.json());
app.use(cors());

// ✅ Log Octave Version to Check if Installed
exec("octave --version", (error, stdout) => {
  if (error) {
    console.error("❌ Octave is NOT installed or cannot be accessed.");
  } else {
    console.log("✅ Octave Version:", stdout);
  }
});

// ✅ Test if Octave Can Execute a Simple Command
exec("octave --silent --eval \"disp('Octave is working!')\"", (error, stdout) => {
  if (error) {
    console.error("❌ Octave execution failed: ", error);
  } else {
    console.log("✅ Octave Execution Test Output:", stdout);
  }
});

// ✅ Define the API route correctly
app.post("/api/optimize", (req, res) => {
  const { R0, R1, C1, R2, C2 } = req.body;

  // ✅ Modify Command to Log Any Octave Execution Issues
  const command = `octave --silent --eval "try; disp('Running optimize_RC'); optimize_RC(${R0}, ${R1}, ${C1}, ${R2}, ${C2}); catch err; disp('Error: Execution Failed'); disp(err.message); exit(1); end"`;

  exec(command, (error, stdout) => {
    console.log("🔹 Octave Command Output:", stdout); // Debug Output in Logs

    if (error) {
      console.error("❌ Octave execution error:", error);
      return res.status(500).json({ error: "Octave execution failed", details: error.message });
    }

    if (stdout.includes("Error: Execution Failed")) {
      console.error("❌ Octave function did not execute properly.");
      return res.status(500).json({ error: "Octave function did not execute properly", output: stdout });
    }

    const match = stdout.match(/R0: ([\d.]+), R1: ([\d.]+), C1: ([\d.]+), R2: ([\d.]+), C2: ([\d.]+)/);
    if (!match) {
      console.error("❌ Failed to parse Octave output.");
      return res.status(500).json({ error: "Failed to parse output", output: stdout });
    }

    res.json({
      R0: parseFloat(match[1]),
      R1: parseFloat(match[2]),
      C1: parseFloat(match[3]),
      R2: parseFloat(match[4]),
      C2: parseFloat(match[5]),
      data: [
        { time: 0, measured: 4.2, estimated: 4.1 },
        { time: 1, measured: 4.1, estimated: 4.05 }
      ],
      error: [
        { time: 0, error: 5 },
        { time: 1, error: 2 }
      ]
    });
  });
});

// ✅ Ensure the server is running on the correct PORT
const PORT = process.env.PORT || 10000;
app.get("/", (req, res) => {
  res.send("✅ Server is running! Use POST /api/optimize");
});

app.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));
