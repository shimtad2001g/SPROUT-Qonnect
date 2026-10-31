# Open Questions for the TraceRight Technical Lead

Six questions. Each one blocks a specific piece of SPROUT work.
Bring this list to the inception meeting; record answers in the blank lines.

## Q1 - Plot identity
Does Qonnect identify a plot separately from a farm?
Blocks: the join key. Without it, no integration is possible.
ANSWER:

## Q2 - ECTMS API access
Is programmatic ECTMS access confirmed, at what latency, and with what
authentication model?
Blocks: the batch-level ECTMS linkage (field ectms_batch_id).
ANSWER:

## Q3 - Farmer data ownership and consent
Who owns the polygon data, and under what consent regime may SPROUT
compute and store attributes derived from it?
Blocks: the data-protection impact assessment.
ANSWER:

## Q4 - First commercial target
Is the consortium's first target an EU buyer, a carbon buyer, or an insurer?
Blocks: sequencing. EUDR first means spatial verification first. Carbon
first means AGB validation first.
ANSWER:

## Q5 - Bid deadline
Is there a specific bid or procurement deadline driving the timeline?
Blocks: milestone dates in the tracker.
ANSWER:

## Q6 - Fabric schema access
Can the TraceRight team share the current Fabric chaincode schema and
the existing DDS generation logic?
Blocks: the DDS integration in Phase 3. SPROUT supplies the spatial
verdict, but we need to know the record shape it must attach to.
ANSWER: