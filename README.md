# NaturalGIS geoscripts
A collection of scripts to handle/download local/remote spatial data and services

<h2>DGT, Direção-Geral do Território</h2>

**download_atom_dgt.sh**

Download raster/vector data from

http://mapas.dgterritorio.pt/inspire/atom/downloadservice.xml

and 

http://mapas.dgterritorio.pt/atom-dgt/downloadservice-cous.xml

and save it into a GPKG datasource.

<h2>ODK, Open data kit</h2>

**odk_geoshape_to_wkt**

**odk_geotrace_to_wkt**

**odk_points_to_wkt**

PostgreSQL functions to transform ODK Geoshapes, ODK Geotraces and ODK points into real WKT geometries.
