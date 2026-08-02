-- PostGIS underpins every spatial operation in LakeScout:
--   * nearest-lake linkage for a property        (KNN <-> operator)
--   * distance from parcel to shoreline          (ST_Distance on geography)
--   * boat launches within a radius              (ST_DWithin)
--   * bbox-filtered lake polygons for the map    (&& on GIST indexes)
CREATE EXTENSION IF NOT EXISTS postgis;
