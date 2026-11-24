# Safety

Omarsenal installs tools that can damage systems and break laws when misused. Read this before testing anything.

## Authorization

Only test systems you own or hold written permission to test. Unauthorized scanning or exploitation is illegal in most countries, including under the US Computer Fraud and Abuse Act and the UK Computer Misuse Act.

Every target profile has an `authorization.md`. The scope guard blocks nmap and masscan in red and purple modes until its status reads `APPROVED`. Only set that when you have written permission in hand.

## Isolation

- Run Omarsenal in a VM, not on your daily machine.
- Snapshot the VM before installing and before each engagement.
- Put the VM on an isolated VLAN or network segment.
- Keep lab containers bound to localhost (the default in `labs/docker-compose.yml`).

## What the scope guard does and does not do

It checks targets passed to `nmap` and `masscan` in interactive shells against `scope.txt` and `out-of-scope.txt`. It is a safety net for typos and stray targets.

It does not inspect other tools, scripts, Metasploit modules, or targets resolved at runtime. You are still responsible for every packet you send.

## Data handling

- Target folders live outside the repo and are git-ignored.
- Session logs may contain credentials and client data. Encrypt the VM disk and delete engagement data when the engagement ends, per your agreement.
- Never commit engagement data, client names or secrets.

## Third-party code

AUR packages and GitHub tools are community code. Omarsenal asks before installing from the AUR. Read the PKGBUILD or install script before you run it.
