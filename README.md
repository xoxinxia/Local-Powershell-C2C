# Local-Powershell-C2C
This is a Lightweight pair of powershell scripts for an interactive agent and the corresponding C2C server. It has bee shared for quick debugging among malware researchers and enthusiasts. The powershell scripts can easily be converted to executables using the popular PS2EXE powershell module!

📖 Overview

Born out of the frustration caused by standard terminal IO synchronization lag (where stdout/stderr blocks routinely collapse or buffer over network boundaries), this repository provides a resilient Controller-to-Agent execution plane. By shifting away from standard script block evaluation wrappers and dropping down into raw .System.Diagnostics.Process manipulation, it achieves a bit-for-bit console serialization layer back to your centralized handler.

⚡ Key Features
Deterministic Stream Framing: Implements an absolute End-Of-Transmission (EOT) frame delimiter mechanism (!!END_OF_TRANSMISSION!!). Say goodbye to random Start-Sleep guesswork and the notorious "Output Buffering Lag" where commands only reflect when the next one is sent.

True Console Fidelity: By wrapping command strings dynamically into low-level process containers, the agent perfectly handles native CMD piping, redirection operators (like 2>nul), batch files (.bat), and direct executable arguments identically to a local session.

On-the-Fly Dynamic Sockets: Features interactive terminal setup routines upon launch. Instantly declare targets, modify active listening ports, or cleanly tear down environments without facing frozen terminal sessions or socket collision errors (TIME_WAIT address locks).

Self-Healing Loop Controls: Hardened with nested error handling filters and structured finally blocks ensuring that network dropouts or severe execution crashes immediately recycle the listener state rather than hanging your management workspace.

🛠️ Deep Dive: The Synchronization Architecture
Standard pipeline redirection often strips away formatting metadata or chokes on multi-line text strings. PoshNexus uses an explicit stream capture cycle to preserve presentation:

Plaintext


  [ C2 Handler ] ======== ( Transmits Raw String ) =======> [ Agent Process ]
         ^                                                         │
         │                                               (cmd.exe /c Invocation)
         │                                                         │
  (Loops Until EOT) <==== [ Merged Byte Stream + EOT Flag ] <======┘
The Request: The controller issues a string command, mapping the transmission cleanly across a StreamWriter pipeline.

The Execution: The Agent abstracts the execution away from native PowerShell script evaluations, feeding it straight into a windowless subsystem.

The Consolidation: Standard Output and Standard Error channels are combined at the engine layer into a single, un-altered string block.

The Flush: The Agent stamps a precise transmission boundaries block, instantly releasing the controller's blocking read loop.

🚀 Getting Started in the Lab
1. Fire up the Controller
Launch the interactive handler and feed it your target testing port:

PowerShell


PS C:\Diagnostics> .\C2-interactive.ps1
Enter the port to listen on (or type 'quit'): 4455
[+] Server is listening on port 4455...
[*] Awaiting agent check-in...
2. Connect the Agent
In your isolated test workspace, run the agent tool and complete the network handshake:

PowerShell


PS C:\Diagnostics> .\agent.ps1
Enter C2 Server IP address: 127.0.0.1
Enter C2 Server port: 4455
[*] Handshake initialized to 127.0.0.1:4455...

3. Analyze Stream Sync
Watch the console gracefully handle complex error masking blocks in real-time:

Plaintext


C2-Console: .\mytestscript.bat 2>nul
--- Command Output ---
[+] Tasks completed cleanly.
----------------------
C2-Console: 


⚖️ Disclaimer
This repository is developed strictly as a reference implementation for network socket debugging, stream buffer handling, and infrastructure research. It is intended solely for educational use in controlled lab environments or authorized adversary emulation exercises.
