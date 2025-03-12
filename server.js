const express = require("express");
const { exec } = require("child_process");
const cors = require("cors");

const app = express();
app.use(express.json());
app.use(cors());

// ✅ Log Octave Version to Verify Installation
exec("octave --version", (error, stdout) => {
  if (error) {
    console.error("❌ Octave is NOT installed or inaccessible.");
  } else {
    console.log("✅ Octave Version:", stdout);
  }
});

// ✅ Test Octave Execution
exec("octave --silent --eval \"disp('Octave is working!')\"", (error, stdout) => {
  if (error) {
    console.error("❌ Octave execution failed: ", error);
  } else {
    console.log("✅ Octave Execution Test Output:", stdout);
  }
});

// ✅ Debug Route: Check Available Files in `/app/readonly/`
app.get("/debug", (req, res) => {
  exec("ls -l /app/readonly/", (error, stdout, stderr) => {
    if (error) {
      console.error("❌ Failed to list files:", stderr);
      return res.status(500).json({ error: "Failed to list files", details: stderr });
    }
    console.log("📂 Available Files:\n", stdout);
    res.json({ files: stdout.split("\n") });
  });
});

// ✅ API Route for Optimizing RC Model
app.post("/api/optimize", (req, res) => {
  const { R0, R1, C1, R2, C2 } = req.body;

  // 🔹 Improved Octave Command with Full Debugging
  const command = `octave --silent --path /app/readonly --eval "
    try;
      disp('🔍 Checking file availability:');
      ls('/app/readonly/');
      
      disp('✅ Running optimize_RC...');
      if exist('optimize_RC', 'file') == 0
        error('⚠️ Function optimize_RC.m not found in /app/readonly/');
      end

      optimize_RC(${R0}, ${R1}, ${C1}, ${R2}, ${C2});

    catch err;
      disp('❌ Error: Execution Failed');
      disp(err.message);
      exit(1);
    end"`;

  // 🔹 Execute Octave Command
  exec(command, (error, stdout, stderr) => {
    console.log("🔹 Octave STDOUT:", stdout);
    console.error("❌ Octave STDERR:", stderr);

    if (error || stderr.includes("Error: Execution Failed")) {
      return res.status(500).json({
        error: "Octave execution failed",
        details: stderr || error.message,
        stdout: stdout,
      });
    }

    // ✅ Extract & Parse Output
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

// ✅ Root Route for API Status
const PORT = process.env.PORT || 10000;
app.get("/", (req, res) => {
  res.send("✅ Server is running! Use POST /api/optimize or GET /debug");
});

// ✅ Start the Server
app.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));
