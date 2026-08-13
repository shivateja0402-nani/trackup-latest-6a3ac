/*
  # LinkedIn profile snapshot

  Stores the scraped LinkedIn profile signals for a lead — location, connection
  and follower counts, recent-activity and decision-maker flags, and where the
  lead came from.

  This is deliberately a SEPARATE column from `outreach`. `outreach` is typed as
  the 8-key OutreachFlow (the generated message copy); writing profile metadata
  there produces a truthy object with none of those keys, which makes the app
  render an empty flow as though one had been generated. The lead-sourcing
  pipeline writes `profile`, the generator writes `outreach`, and neither
  clobbers the other.

  Idempotent.
*/

ALTER TABLE leads ADD COLUMN IF NOT EXISTS profile jsonb;

/*
  Rescue existing rows: leads inserted by the sourcing pipeline before this
  migration have their profile snapshot sitting in `outreach`. Move it across
  and clear `outreach` so the app stops showing a blank "Regenerate flow".

  Identified by the absence of connection_note — a real OutreachFlow always has
  one, a profile snapshot never does.
*/
UPDATE leads
SET profile = outreach,
    outreach = NULL
WHERE outreach IS NOT NULL
  AND profile IS NULL
  AND NOT (outreach ? 'connection_note');
