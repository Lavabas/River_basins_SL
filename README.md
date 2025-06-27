# River_basins_SL
It shows the river basins of Sri Lanka through a map created using R. 
![SL_Rivers_map](images/srilanka_river_basins.png)
This project extracts, processes, and visualizes river basins and river networks in **Sri Lanka** using spatial hydrological datasets from the **HydroSHEDS** database.
The final map highlights major sub-basins and their associated rivers with width classes and color variations using **ggplot2** and **sf** in R.

🌐 Data Sources
1. HydroBASINS (Level 3) for sub-basin boundaries:
   https://data.hydrosheds.org/file/HydroBASINS/standard/hybas_as_lev03_v1c.zip
2. HydroRIVERS for river lines:
   https://data.hydrosheds.org/file/HydroRIVERS/HydroRIVERS_v10_as.gdb.zip
3. Country boundary from GISCO (Eurostat)

🖋️ Citation
Prepared by: Lavanya Baskaran
Source: © World Wildlife Fund, Inc. (2006–2013) HydroSHEDS database
https://www.hydrosheds.org

🛠️ Notes
Adjust flow width or color scale using ORD_FLOW as needed.
North arrow and scale bar can be added with ggspatial::annotation_* functions if needed.
Set working directory with getwd() or use RStudio Projects.
