# Variational Causal Bayesian Inference for Seismic Multi-hazard and Impact Estimation from Satellite Images

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.7319726.svg)](https://doi.org/10.5281/zenodo.7319726) [![MIT license](https://img.shields.io/badge/License-MIT-blue.svg)](https://lbesson.mit-license.org/)

This GitHub repository contains the code, data, and figures for the Nature Communications paper [_Seismic Multi-hazard and Impact Estimation via Causal Inference from Satellite Imagery_](https://github.com/SusuXu/VBCI). If you have any questions, please contact [susu.xu@stonybrook.edu](mailto:susu.xu@stonybrook.edu).

## Installation
This code depends on MALTAB R2022a, QGIS 3.22.2-Białowieża, and any newer versions.

## Data
Download and store the input raster TIF files for damage proxy map, building footprint, prior landslide model, and prior liquefaction model to local directory. Please make sure that they have consistent size and dimension. In most cases, prior models have much lower resolutions than damage proxy map, so it is necessary to discretize the prior estimations to make the map size the same as the damage proxy maps (though the resolution stays low). We studied the following four earthquake events:
- Earthquake Event
  - 2016_central_italy, [USGS Event Page](https://earthquake.usgs.gov/earthquakes/eventpage/us10006g7d)
  - 2018_hokkaido_japan_5m, [USGS Event Page](https://earthquake.usgs.gov/earthquakes/eventpage/us2000h8ty/)
  - 2018_hokkaido_japan_30m, [USGS Event Page](https://earthquake.usgs.gov/earthquakes/eventpage/us2000h8ty/), (same as the previous one but with different resolution)
  - 2019_ridgecrest, [USGS Event Page](https://earthquake.usgs.gov/earthquakes/eventpage/ci38457511)
  - 2020_puerto_rico, [USGS Event Page](https://earthquake.usgs.gov/earthquakes/eventpage/us70006vll)

We have made all the post-processed inputs and outputs available inside the `data` folder. Supplementary datasets are provided below if anyone would like to visualize the vector representation of building footprint and ground truth datasets. The MATLAB codes will need the TIF files only, which are results of the post-processing of supplementary datasets. Each earthquake event has the following datasets:
- Input Data
  - PLS: `data/<event>/prior_models/<event>_prior_landslide_model.tif`
  - PLF: `data/<event>/prior_models/<event>_prior_liquefaction_model.tif`
  - BD: `data/<event>/building_footprint/<event>_building_footprint_rasterized.tif`
  - DPM: `data/<event>/damage_proxy_map/<event>_damage_proxy_map.tif`
- Output Data
  - QLS: `data/<event>/posterior_models`
  - QLS: `data/<event>/posterior_models`
  - QBD: `data/<event>/building_damage_model`
- Validation or Performance Assessment
  - GTLS: `data/<event>/ground_truth/<event>_landslide_ground_truth_rasterized.tif`
  - GTLF: `data/<event>/ground_truth/<event>_liquefaction_ground_truth_rasterized.tif`
  - GTBD: `data/<event>/ground_truth/<event>_building_damage_ground_truth_rasterized.tif`
- Supplementary Datasets
  - Building Footprint GIS Shapefile: `data/<event>/building_footprint/<event>_building_footprint.zip`
  - Landslide Ground Truth GIS Shapefile: `data/<event>/ground_truth/<event>_landslide_ground_truth.zip`
  - Liquefaction Ground Truth GIS Shapefile: `data/<event>/ground_truth/<event>_liquefaction_ground_truth.zip`
  - Building Damage Ground Truth GIS Shapefile: `data/<event>/ground_truth/<event>_building_damage_ground_truth.zip`




## Code

The main codes locate under the directory of method.
updating.m is the main function to optimize the causal Bayesian inference. In the updating.m, "location" refers to the directory storing DPM, building footprint(BD.tif), prior landslide(PLS.tif), and prior liquefaction(PLF.tif). In updating.m: 
* prune_type represents the type of pruning the original causal graph to accelerate the computing. "double" refers to symmetric pruning where given a location, prune one node from LS and LF if the absolute difference between prior LS and LF is larger than a given threshold specified by sigma (which is often set as 0 or median of the difference). "single" refers to an asymmetric pruning where given a location, prune LF node if LS is larger than LF+sigma and prune LS if LF is larger than LS, or the opposite case. 
* sigma refers to pruning threshold to retain only one node from LS and LF in the locations where prior models are very sure that only one of the hazards exist. If you are confident with the prior model, you can set sigma as 0, otherwise we will recommend to try median or mean of the absolute differences. 
* lambda and regu_type refer to the regularization term. regu_type == 1 refers to that the model will rely more on DPM, regu_type == 2 refers to that the model will rely more on the prior model. lambda control the levels of regularization, higher means more strongly restricting the impacts of DPM (regu_type==2) or prior model(regu_type==1). We recommend to setup lambda as 0 if you do not have any prior understanding about the confidence level of DPM and prior models.
* rho is the learning rate for optimization, delta is the aceptable tolerance level for convergence. eps_0 is a small number to get rid of negative entropy. 
* Nq is the number of posterior probability iterations at each location in each epoch. We often set it as 10.
* SVI.m is the stochastic variational inference process which optimizes the posterior and weights. 
* performance.m refers to the evaluation metric, including true positive rate, false positive rate, ROC, DET, PR, and AUC calculation. 

## Results
The results are automatically saved in the location specified by 'filename' in updating.m. final_QLS, final_QLF are the landslide, liquefaction estimation by our model, respectively. opt_QBD is the building damage (BD) estiamtion by our model. local is the finally updated pruning strategy, local = 1,3 represent only LS or LS+BD, local = 2,4 refer to only LF or LF+BD, local = 5 refers to LS+LF, local=6 refers to LS+LF+BD. If you are very sure about the mutual exclusive between LS and LF at some locations, you can incorporate that in the original pruning strategies (prune.m).

The system is built based on the causal graph depicting the physical interdependencies among different seismic hazards, impacts, and Damage Proxy Maps (DPMs).
<p align="center">
    <img src="figures/causal_graph.png" width="500"\>
</p>


### 2018 Hokkaido Earthquake

<p align="center">
    <img src="figures/hokkaido_roc.jpg" width="400"\>
</p>

We test the performance of our system on multiple earthquake events, including the 2018 Hokkaido earthquake, 2016 Central Italy earthquake, the 2019 Ridgecrest earthquake, and the 2020 Puerto Rico earthquake. We here show a comparison between our prediction results and existing USGS landslide model for landslide in Hokkaido. 

## Repository Structure
```
├───code
│   ├───method
│   │       df.m
│   │       f.m
│   │       Loss.m
│   │       parder.m
│   │       pruning.m
│   │       SVI.m
│   │       Tfxn.m
│   │       updating.m
│   │
│   └───performance
│           binaryerror.m
│           performance.m
│           rocdetpr.m
│
├───data
│   ├───2016_central_italy
│   │   ├───building_damage_model
│   │   │       2016_central_italy_building_damage_model.tif
│   │   │
│   │   ├───building_footprint
│   │   │       2016_central_italy_building_footprint.zip
│   │   │       2016_central_italy_building_footprint_rasterized.tif
│   │   │
│   │   ├───damage_proxy_map
│   │   │       2016_central_italy_damage_proxy_map.tif
│   │   │
│   │   ├───ground_truth
│   │   │       2016_central_italy_building_damage_ground_truth.zip
│   │   │       2016_central_italy_building_damage_ground_truth_rasterized.tif
│   │   │       2016_central_italy_landslide_ground_truth.zip
│   │   │       2016_central_italy_landslide_ground_truth_rasterized.tif
│   │   │
│   │   ├───posterior_models
│   │   │       2016_central_italy_posterior_landslide_model.tif
│   │   │       2016_central_italy_posterior_liquefaction_model.tif
│   │   │
│   │   └───prior models
│   │           2016_central_italy_prior_landslide_model.tif
│   │           2016_central_italy_prior_liquefaction_model.tif
│   │
│   ├───2018_hokkaido_japan_30m
│   │   ├───building_damage_model
│   │   │       2018_hokkaido_japan_30m_building_damage_model.tif
│   │   │
│   │   ├───building_footprint
│   │   │       2018_hokkaido_japan_30m_building_footprint.zip
│   │   │       2018_hokkaido_japan_30m_building_footprint_rasterized.tif
│   │   │
│   │   ├───damage_proxy_map
│   │   │       2018_hokkaido_japan_30m_damage_proxy_map.tif
│   │   │
│   │   ├───ground_truth
│   │   │       2018_hokkaido_japan_30m_landslide_ground_truth.zip
│   │   │       2018_hokkaido_japan_30m_landslide_ground_truth_rasterized.tif
│   │   │       
│   │   ├───posterior_models
│   │   │       2018_hokkaido_japan_30m_posterior_landslide_model.tif
│   │   │       2018_hokkaido_japan_30m_posterior_liquefaction_model.tif
│   │   │
│   │   └───prior models
│   │           2018_hokkaido_japan_30m_prior_landslide_model.tif
│   │           2018_hokkaido_japan_30m_prior_liquefaction_model.tif
│   │
│   ├───2018_hokkaido_japan_5m
│   │   ├───building_damage_model
│   │   │       2018_hokkaido_japan_5m_building_damage_model.tif
│   │   │
│   │   ├───building_footprint
│   │   │       2018_hokkaido_japan_5m_building_footprint.zip
│   │   │       2018_hokkaido_japan_5m_building_footprint_rasterized.tif
│   │   │
│   │   ├───damage_proxy_map
│   │   │       2018_hokkaido_japan_5m_damage_proxy_map.tif
│   │   │
│   │   ├───ground_truth
│   │   │       2018_hokkaido_japan_5m_landslide_ground_truth.zip
│   │   │       2018_hokkaido_japan_5m_landslide_ground_truth_rasterized.tif
│   │   │
│   │   ├───posterior_models
│   │   │       2018_hokkaido_japan_5m_posterior_landslide_model.tif
│   │   │       2018_hokkaido_japan_5m_posterior_liquefaction_model.tif
│   │   │
│   │   └───prior models
│   │           2018_hokkaido_japan_5m_prior_landslide_model.tif
│   │           2018_hokkaido_japan_5m_prior_liquefaction_model.tif
│   │
│   ├───2019_ridgecrest
│   │   ├───building_damage_model
│   │   │       2019_ridgecrest_building_damage_model.tif
│   │   │
│   │   ├───building_footprint
│   │   │       2019_ridgecrest_building_footprint.zip
│   │   │       2019_ridgecrest_building_footprint_rasterized.tif
│   │   │
│   │   ├───damage_proxy_map
│   │   │       2019_ridgecrest_damage_proxy_map.tif
│   │   │
│   │   ├───ground_truth
│   │   │       2019_ridgecrest_building_damage_ground_truth.zip
│   │   │       2019_ridgecrest_building_damage_ground_truth_rasterized.tif
│   │   │       2019_ridgecrest_landslide_ground_truth.zip
│   │   │       2019_ridgecrest_landslide_ground_truth_rasterized.tif
│   │   │       2019_ridgecrest_liquefaction_ground_truth.zip
│   │   │       2019_ridgecrest_liquefaction_ground_truth_rasterized.tif
│   │   │
│   │   ├───posterior_models
│   │   │       2019_ridgecrest_posterior_landslide_model.tif
│   │   │       2019_ridgecrest_posterior_liquefaction_model.tif
│   │   │
│   │   └───prior models
│   │           2019_ridgecrest_prior_landslide_model.tif
│   │           2019_ridgecrest_prior_liquefaction_model.tif
│   │
│   └───2020_puerto_rico
│       ├───building_damage_model
│       │       2020_puerto_rico_building_damage_model.tif
│       │
│       ├───building_footprint
│       │       2020_puerto_rico_building_footprint.zip
│       │       2020_puerto_rico_building_footprint_rasterized.tif
│       │
│       ├───damage_proxy_map
│       │       2020_puerto_rico_damage_proxy_map.tif
│       │
│       ├───ground_truth
│       │       2020_puerto_rico_building_damage_ground_truth.zip
│       │       2020_puerto_rico_building_damage_ground_truth_rasterized.tif
│       │       2020_puerto_rico_landslide_ground_truth_part1.zip
│       │       2020_puerto_rico_landslide_ground_truth_part2.zip
│       │       2020_puerto_rico_landslide_ground_truth_part3.zip
│       │       2020_puerto_rico_landslide_ground_truth_rasterized.tif
│       │       2020_puerto_rico_liquefaction_ground_truth.zip
│       │       2020_puerto_rico_liquefaction_ground_truth_rasterized.tif
│       │
│       ├───posterior_models
│       │       2020_puerto_rico_posterior_landslide_model.tif
│       │       2020_puerto_rico_posterior_liquefaction_model.tif
│       │
│       └───prior models
│               2020_puerto_rico_prior_landslide_model.tif
│               2020_puerto_rico_prior_liquefaction_model.tif
│
└───figures
    │   causal_graph.png
    │   hokkaido_roc.jpg
    │
    ├───fig1
    │       fig1_causal_graph_editable.pptx
    │       fig1_causal_graph_flattened.pdf
    │
    ├───fig2
    │   │   fig2_full_auc_results_editable.pdf
    │   │   fig2_full_auc_results_flattened.pdf
    │   │
    │   └───subplots
    │           fig2a.pdf
    │           fig2b.pdf
    │           fig2c.pdf
    │           fig2d.pdf
    │           fig2e.pdf
    │           fig2f.pdf
    │           fig2g.pdf
    │           fig2h.pdf
    │           fig2i.pdf
    │
    ├───fig3
    │       fig3_puertorico_editable.pdf
    │       fig3_puertorico_flattened.pdf
    │
    ├───fig4
    │       fig4_japan30m_editable.pdf
    │       fig4_japan30m_flattened.pdf
    │
    ├───fig5
    │   │   fig5_editable.pdf
    │   │   fig5_flattened.pdf
    │   │
    │   └───subplots
    │           fig5a_fig5b_weights_editable.pdf
    │           fig5a_fig5b_weights_editable.pptx
    │           fig5c.pdf
    │           fig5d.pdf
    │
    ├───supplementaryfig1
    │       supplementaryfig1_centralitaly_editable.pdf
    │       supplementaryfig1_centralitaly_flattened.pdf
    │
    ├───supplementaryfig2
    │       supplementaryfig2_ridgecrest_editable.pdf
    │       supplementaryfig2_ridgecrest_flattened.pdf
    │
    ├───supplementaryfig3
    │       supplementaryfig3_japan5m_editable.pdf
    │       supplementaryfig3_japan5m_flattened.pdf
    │
    ├───supplementaryfig4
    │   │   supplementaryfig4_editable.pdf
    │   │   supplementaryfig4_flattened.pdf
    │   │
    │   └───subplots
    │           supplementaryfig4a_fig4b_weights_editable.pdf
    │           supplementaryfig4a_fig4b_weights_editable.pptx
    │           supplementaryfig4c.pdf
    │           supplementaryfig4d.pdf
    │
    └───supplementaryfig5
        │   supplementaryfig5_editable.pdf
        │   supplementaryfig5_flattened.pdf
        │
        └───subplots
                supplementaryfig5a.pdf
                supplementaryfig5b.pdf
```

## Acknowledgements
This project is supported by USGS, Stony Brook University, and Stanford Unviersity. 
