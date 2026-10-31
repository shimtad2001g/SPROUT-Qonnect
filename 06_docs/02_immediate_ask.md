# Immediate Ask - Letter to the TraceRight Technical Lead

**From:** Shimeles Tadesse Zelelew (Project SPROUT)
**To:** TraceRight Satellite International Consortium - Technical Lead
**Date:** 2026-10-31
**Subject:** Five integration actions to begin the shared-partnership work

---

Dear TraceRight Technical Lead,

Over the past cycle I have built, tested, and delivered a running
SPROUT-Qonnect integration - not a proposal, a working API and pipeline
that converts Qonnect farm polygons into EUDR-compatible spatial
verification with a batch-level ECTMS GeoJSON output. The evidence pack
is attached.

To move from demonstration to consortium integration, five specific
actions are needed from your side. Each has an evidence artifact already
attached so you can see what we would be integrating into.

## Ask 1 - Nominate a technical counterpart

A named person on your side who will:
- Review 01_technical_capability.md
- Run python demo.py once and confirm the pipeline output matches
- Sign off on the API contract frozen in 01_discovery/00_alignment_contract.md

Time required from your side: 30 minutes.

## Ask 2 - Confirm the commercial model

Three options, in increasing commitment order:

- A. Licensed API - SPROUT retained, consortium pays per-polygon or annual
- B. Embedded module - SPROUT IP contributed into Fabric, revenue share
- C. Joint venture - co-owned asset, shared governance

Recommendation: Option B. It maximises integration credibility for the
coming bid while preserving a path to shared ownership.

Action requested: indicate preference or request a call to discuss.

## Ask 3 - Share ECTMS and Fabric documentation

Two specific items:
- ECTMS API contract (authentication model, rate limits, batch ID format)
- Fabric chaincode schema for the current DDS generation logic

Both are needed for the Phase 5 handover to your team. SPROUT is
currently ectms_batch_id = NULL because ECTMS access is not confirmed;
that field becomes live when this is shared.

Data-sharing agreement: if a formal NDA is needed first, tell me the
process and I will complete it.

## Ask 4 - Confirm the first commercial target

Three plausible targets, in different timelines:

- EU buyer (EUDR-driven): need spatial verification NOW; hard deadlines
  are Dec 2026 for large operators and Jun 2027 for SMEs
- Carbon buyer (Verra VM0047): need AGB accuracy and uncertainty budget
- Insurer (crop insurance): need historical biomass baselines

The sequencing of the integration depends entirely on which is first.
My recommendation: EU buyer, because the regulatory deadline is fixed
and the technical work is done.

## Ask 5 - Schedule the inception meeting

Once Asks 1-4 are answered, a 90-minute inception meeting to:
- Sign 01_discovery/00_alignment_contract.md
- Agree the milestone table in 00_admin/STEP_TRACKER.md
- Commit to the first joint commercial target and its deadline

## Attached

- 00_executive_summary.md - one-page overview
- 01_technical_capability.md - full technical spec and gaps
- 03_demo_cheat_sheet.md - how to run the demo yourself in 2 minutes
- 04_validation/sprout_geospatial_validation_report.md - audit report

## Closing

None of these asks is open-ended. Each has a specific artifact attached
and a specific deliverable on your side. The work to demonstrate the
integration is complete; what remains is confirmation and commitment.

I look forward to your response.

Respectfully,
Shimeles Tadesse Zelelew
Project SPROUT