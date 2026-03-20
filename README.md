# Platform Engineer Take-Home Test

## Overview

This task is intended to be timeboxed to **maximum 2 hours**. In this time window, feel free to pick one or two scenarios from the list presented below. 

### Your Task

1. **Analyze the scenario** - prepare any questions you may need to ask before deciding on the right solution (think about technical and non-technical stakeholders)
2. **Propose a technical brief** addressing:
   - How can this requirement be achieved?
   - What are the assumptions you've made?
   - What questions/clarifications are needed?
   - Which parts of the proposal are optional and depend on those answers?
   - What are the strengths and weaknesses of the proposed solution?

Be prepared to discuss your solution in the technical interview, with extra questions, requirements or "what if…" scenarios being added.

---

## Scenarios

### [Scenario 1: AWS Backup Cost Optimization](task1/)

**Context:** The business is concerned about the ongoing AWS bill. After superficial investigation, it was discovered backups drive a significant proportion of the spending.

**Materials provided:**
- Spreadsheets with backup cost summary across 2-3 AWS accounts
- Terraform module describing the existing backup policy

**Your objective:** Investigate the situation, propose possible solutions to lower the cost, think about tradeoffs and decisions the business can take to lower the cost.

📁 **[View Task 1 details →](task1/README.md)**

---

### [Scenario 2: EKS Cluster Decommissioning](task2/)

**Context:** Our EKS clusters are created by the attached EKS terraform module. Some of those clusters are no longer needed and should be decommissioned - we do not want to pay for empty infrastructure.

**Assumptions:**
- Decommissioning may happen 1-2 times a month
- We want to avoid engineers performing repetitive manual tasks
- We prioritize automation wherever possible

**Materials provided:**
- Terraform module describing the existing EKS setup
- Variable files for multiple partner accounts

**Your objective:** Look at the attached terraform repository that provisions our EKS clusters and make a plan regarding the ways we should proceed.

📁 **[View Task 2 details →](task2/README.md)**

---

## Submission Guidelines

Please prepare your solution as a written document that includes:
- Your analysis of the chosen scenario(s)
- Questions for stakeholders
- Technical solution proposal
- Trade-offs and considerations
- Any assumptions made

Good luck! 🚀
