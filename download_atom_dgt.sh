#!/bin/bash
#SET CODES FOR SOME COLOR CODED MESSAGES
RED='\033[0;31m'
NC='\033[0m'

echo "Starting the download process of the data publishes in the DGT's ATOM services and its conversion to Geopackage"

#CREATE A FOLDER IN /tmp FOR TEMPORARY DATA
mkdir /tmp/atom_dgt

#PARSE THE DGT ATOM FEED TO GET THE ADDRESSES POINTING TO THE DATSOURCES
#WE NEED TO SAVE THE XML LOCALLY BECAUSE PARSING THEM REMOTELY DOES NOT WORK WITH GDAL > 2.2
wget -q http://mapas.dgterritorio.pt/inspire/atom/downloadservice.xml -O /tmp/atom_dgt/downloadservice.xml && ogrinfo /tmp/atom_dgt/downloadservice.xml georss | grep -w "link2_href (String) =" | while read -r line ; do

url=$(echo $line | cut -c23-)
echo -e "Download and processing: ${RED}$url${NC}"

xml="${url##*/}"

#GET THE CRS OF THE DATSOURCE
wget -q $url -O /tmp/atom_dgt/$xml
ogrinfo -ro /tmp/atom_dgt/$xml georss | grep -w "category_term (String) ="  | tail -1 | while read -r crs ; do
crs=${crs: -4}

#GET THE URL POINTING TO THE ZIP OF THE DATASOURCE
ogrinfo -ro /tmp/atom_dgt/$xml georss | grep -w "link_href (String) =" | while read -r line_zip ; do
zip=$(echo $line_zip | cut -c22-)

nome="${zip##*/}"
noext="${nome%.*}"
noext_lower=${noext,,}

#SET THE NAME FOR THE COS MAPS AS THEY ARE ORIGINALLY AVAILABLE SPLIT IN SEVERAL PARTS AND WE WILL MERGE THEM INTO 1 SINGLE LAYER
if [[ $nome == *"COS2018"* ]]; then
nome_camada=" -nln cos2018_v1_atom"
elif [[ $nome == *"COS2015"* ]]; then
nome_camada=" -nln cos2015_v1"
elif [[ $nome == *"COS2010"* ]]; then
nome_camada=" -nln cos2010_v1"
elif [[ $nome == *"COS2007"* ]]; then
nome_camada=" -nln cos2007_v2"
else
nome_camada=" -nln $noext_lower"
fi

#EXCLUDE FROM PROCESSING A FEW DATASOURCES THAT ARE NOT DOWNLOADABLE AS THEY ARE PASSWORD PROTECTED
if ! [[ $url == *"Altimetria"* ]] && ! [[ $url == *"RedeTransportes"* ]] && ! [[ $url == *"Hidrografia"* ]]; then

#SOME OF THE DATASOURCES ARE RASTERS, WE MUST HANDLE THEM IN A DIFFERENT WAY COMPARED TO VECTORS
if [[ $url == *"mdt"* ]] || [[ $url == *"MDT"* ]] || [[ $url == *"geoide"* ]]; then

#DOWNLOAD, UNZIP AND IMPORT THE RASTERS
wget -q $zip -O /tmp/atom_dgt/$nome
unzip -qq -j -o /tmp/atom_dgt/$nome -d /tmp/atom_dgt/

FILES=/tmp/atom_dgt/*.tif
for f in $FILES
do
nome_tif="${f##*/}"
noext_tif="${nome_tif%.*}"
noext_tif_lower=${noext_tif,,}
  gdal_translate -q -of GPKG $f atom_dgt.gpkg -co RASTER_TABLE=$noext_tif_lower -co APPEND_SUBDATASET=YES -a_srs EPSG:$crs
  gdaladdo -q -oo TABLE=$noext_tif_lower atom_dgt.gpkg 2 4 8 16 32
  rm /tmp/atom_dgt/$noext_tif.*
done
else
#DOWNLOAD, UNZIP AND IMPORT THE VECTORS
#WE IMPORT FIRST AS SPATIALITE BECAUSE WE WANT THE COLUMN NAMES LAUNDERED, SOMETHING THAT IMPORTING DIRECTLY INTO GPKG DOES NOT
ogr2ogr -q -f SQlite -dsco SPATIALITE=YES /tmp/atom_dgt/atom_dgt_temp.sqlite $append /vsizip//vsicurl/$zip -lco SPATIAL_INDEX=YES -lco GEOMETRY_NAME=geom -a_srs EPSG:$crs $nome_camada -nlt PROMOTE_TO_MULTI
ogr2ogr -q -f GPKG atom_dgt.gpkg -append /tmp/atom_dgt/atom_dgt_temp.sqlite $si $gn -a_srs EPSG:$crs $nome_camada -nlt PROMOTE_TO_MULTI -lco GEOMETRY_NAME=geom -lco SPATIAL_INDEX=YES -lco GEOMETRY_NAME=geom &> /dev/null
rm /tmp/atom_dgt/atom_dgt_temp.sqlite
fi
fi

done
done
done


#REPEAT ALL THE ABOVE FOR A DIFFERENT ATOM SERVICE
wget -q http://mapas.dgterritorio.pt/atom-dgt/downloadservice-cous.xml -O /tmp/downloadservice-cous.xml && ogrinfo /tmp/downloadservice-cous.xml georss | grep -w "link2_href (String) =" | while read -r line ; do
url=$(echo $line | cut -c23-)
echo -e "Download and processing: ${RED}$url${NC}"

xml="${url##*/}"
wget -q $url -O /tmp/atom_dgt/$xml
ogrinfo -ro /tmp/atom_dgt/$xml georss | grep -w "category_term (String) ="  | tail -1 | while read -r crs ; do
crs=${crs: -4}

ogrinfo -ro /tmp/atom_dgt/$xml georss | grep -w "link_href (String) =" | while read -r line_zip ; do
zip=$(echo $line_zip | cut -c22-)
nome="${zip##*/}"
noext="${nome%.*}"
noext_lower=${noext,,}

if [[ $nome == *"COS1995"* ]]; then
nome_camada=" -nln cos1995_v1"
fi

if ! [[ $url == *"CLC2012"* ]] && ! [[ $url == *"CLC2006"* ]] && ! [[ $url == *"CLC2000"* ]]; then
if [[ $url == *"HRL"* ]] || [[ $url == *"Impermeabilidade"* ]]; then

wget -q $zip -O /tmp/atom_dgt/$nome
unzip -qq -j -o /tmp/atom_dgt/$nome -d /tmp/atom_dgt/

FILES=/tmp/atom_dgt/*.tif
for f in $FILES
do
nome_tif="${f##*/}"
noext_tif="${nome_tif%.*}"
noext_tif_lower=${noext_tif,,}
  gdal_translate -q -of GPKG $f atom_dgt.gpkg -co RASTER_TABLE=$noext_tif_lower -co APPEND_SUBDATASET=YES -a_srs EPSG:$crs
  gdaladdo -q -oo TABLE=$noext_tif_lower atom_dgt.gpkg 2 4 8 16 32
  rm /tmp/atom_dgt/$noext_tif.*
done
else
ogr2ogr -q -f SQlite -dsco SPATIALITE=YES /tmp/atom_dgt/atom_dgt_temp.sqlite $append /vsizip//vsicurl/$zip -lco SPATIAL_INDEX=YES -lco GEOMETRY_NAME=geom -a_srs EPSG:$crs $nome_camada -nlt PROMOTE_TO_MULTI
ogr2ogr -q -f GPKG atom_dgt.gpkg -append /tmp/atom_dgt/atom_dgt_temp.sqlite $si $gn -a_srs EPSG:$crs $nome_camada -nlt PROMOTE_TO_MULTI -lco GEOMETRY_NAME=geom -lco SPATIAL_INDEX=YES -lco GEOMETRY_NAME=geom &> /dev/null
rm /tmp/atom_dgt/atom_dgt_temp.sqlite
fi
fi

done
done
done

#FOR THE COS2018 MAP WE CAN IMPROVE THE ATTRIBUTES TABLE BY REORGANIZING IT, AND JOINING THE ORIGINAL ONE WITH THE FULL NOMENCLATURE/LEGEND THAT INCLUDES ALL THE COS LEVELS
echo "Reorganizing the columns of COS2018 map..."
ogr2ogr -update -f GPKG -dialect SQLITE -sql 'SELECT fid,"ID" AS id,SUBSTR("COS2018_n1",1,1) AS cos2018_n1,SUBSTR("COS2018_n1",3) AS cos2018_n1_descricao,"COS2018_n4" AS cos2018_n4,SUBSTR("COS2018_Lg",9) AS cos2018_n4_descricao, "AREA" AS area, ST_Area(geom)/10000 AS area_hectares, ST_Buffer(geom,0) AS geom FROM cos2018_v1_atom' atom_dgt.gpkg atom_dgt.gpkg -nln cos2018_v1_temp -lco "SPATIAL_INDEX=YES" -lco "GEOMETRY_NAME=geom" -nlt "MULTIPOLYGON" -a_srs EPSG:3763

echo "Reorganization of the columns of COS2018 map completed"
ogr2ogr -f GPKG -append atom_dgt.gpkg /vsicurl/https://www.naturalgis.pt/opendata/vectores/dgt/atom/nomenclatura_cos_2018.csv -nln nomenclatura_cos_2018

echo "Download of COS2018 nomenclature completed"

echo "Joining the original attributes ot the COS2018 map with the complete nomenclature..."
ogr2ogr -f GPKG -append -dialect SQLITE -sql "SELECT a.fid,a.id,a.cos2018_n1,a.cos2018_n1_descricao,b.n2 AS cos2018_n2,b.n2_desc AS cos2018_n2_descricao,b.n3 AS cos2018_n3,b.n3_desc AS cos2018_n3_descricao,a.cos2018_n4,a.cos2018_n4_descricao,a.area_hectares,a.geom FROM cos2018_v1_temp a INNER JOIN nomenclatura_cos_2018 b ON b.n4 = a.cos2018_n4" atom_dgt.gpkg atom_dgt.gpkg -nln cos2018_v1 -lco "SPATIAL_INDEX=YES" -lco "GEOMETRY_NAME=geom" -nlt "MULTIPOLYGON" -a_srs EPSG:3763

echo "Join completed"

echo "Deleting the temporary tables..."
ogrinfo -q -dialect SQLITE -sql "DROP TABLE cos2018_v1_atom" atom_dgt.gpkg
ogrinfo -q -dialect SQLITE -sql "DROP TABLE cos2018_v1_temp" atom_dgt.gpkg

echo "Vacuuming process started..."
ogrinfo -q -dialect SQLITE -sql "VACUUM" atom_dgt.gpkg

#REMOVE ALL THE TEMP DATA
rm -R /tmp/atom_dgt
echo "Operations completed"
