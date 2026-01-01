ALTER TABLE garden_bed
ADD COLUMN ordinal INTEGER NOT NULL DEFAULT 0;

UPDATE garden_bed
SET ordinal = id
WHERE ordinal = 0;
