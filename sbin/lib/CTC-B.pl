# FileSystems.yaml
#
# YAML descp of file systems to be monitored
#
#Group
#  +Project (or a department name, used in Web descp)
#     +File System Name (unique and MYSQL safe)
#         +Volume Specifications
#
---
CTC-B Cluster :
  Title       : CTC B Cluster Storage Reports
  descp : High Performance Computing Data Storage supporting CTC cluster.  Storage space used to support input and output for cluster jobs.  This volume does not have a backup policy.
  CTC-B Storage :
    descp  : Project Storage CTC Cluster
    project :
      descp   : Project Storage
      source  : /fstool/project
      path    : /SFS/project
      table   : CTCB_project
      fname   : project.csv
      report  : fsreport
      array   : ctcIsilon2
      owner   : Jason Huges
    SRS       : 
      descp   : Sequence Retrival System 
      source  : /SFS/SRS
      path    : /SFS/SRS
      detail  : /SFS/SRS
      array   : sc29
      fname   : SRS.csv
      table   : CTCB_SRS
      report  : detail 
      owner   : Guochun Xie 
    genomics  : 
      descp   : Genomics Projects
      source  : /fstool/project
      path    : /SFS/project/genomics/Projects
      detail  : /fstool/project/genomics/Projects
      array   : ctcIsilon2
      owner   : Jason Huges
      table   : CTCB_project
      report  : detail
    gentools  : 
      descp   : Genomics Tools 
      source  : /fstool/project
      path    : /SFS/project/genomics/tools
      detail  : /fstool/project/genomics/tools
      array   : ctcIsilon2
      owner   : Jason Huges
      table   : CTCB_project
      report  : detail
    genome    : 
      descp   : Genome Projects
      source  : /fstool/project
      path    : /SFS/project/genomics/genome/Projects
      detail  : /fstool/project/genomics/genome/Projects
      array   : ctcIsilon2
      owner   : Jason Huges
      table   : CTCB_project
      report  : detail
    genetics :
      descp   : Genetics Projects
      source  : /fstool/project
      path    : /SFS/project/genetics/projects
      detail  : /fstool/project/genetics/projects
      array   : ctcIsilon2
      owner   : Jason Huges
      table   : CTCB_project
      report  : detail
    osd :
      descp   : OSD Projects
      source  : /fstool/project
      path    : /SFS/project/genetics/osd/Projects
      detail  : /fstool/project/genomics/osd/Projects
      array   : ctcIsilon2
      owner   : Jason Huges
      table   : CTCB_project
      report  : detail 
    mpData :
      descp   : Molecular Profile Data
      path    : /SFS/project/mpData
      source  : /SFS/project/mpData
      table   : CTCB_mpData
      fname   : mpData.csv
      report  : fsreport
      array   : sc27
      owner   : Blake Dubois
    scratch :
      descp   : Operational Job Storage
      path    : /SFS/scratch
      source  : /SFS/scratch
      fname   : scratch.csv
      report  : fsreport
      array   : sc29
      table   : CTCB_scratch
      owner   : Shared
    omicsoft  :
      descp   : Omic Software Project 
      path    : /SFS/project/omicsoft
      source  : /fstool/omicsoft
      table   : CTCB_omicsoft
      fname   : omicsoft.csv
      array   : sc27 
      report  : fsreport
      owner   : Omic Soft 
    home :
      descp  : User Home Directory 
      path    : /SFS/user/ctc
      source  : /home
      fname   : home.csv
      table   : CTCB_home
      report  : fsreport
      array   : NetApp23 
      owner   : Shared (this means you) 
    data1    :
      descp  : Archive stuff 
      path    : /SFS/archive/data1
      source  : /SFS/archive/data1
      table   : CTCB_data1
      array   : NetApp23
      fname   : data1.csv
      report  : fsreport
      owner   : Shared Archive 
    store_prod :
      descp : Omics Prod
      path    : /SFS/project/omicsoft/data/store-prod
      source  : /SFS/project/omicsoft/data/store-prod
      table   : CTCB_store_prod
      fname   : store-prod.csv
      report  : fsreport
      array   : NetApp25
    hdf5_prod :
      descp   : Omics HDF5 Prod
      path    : /SFS/project/omicsoft/data/hdf5-prod
      source  : /SFS/project/omicsoft/data/hdf5-prod
      fname   : hdf5-prod.csv
      table   : CTCB_hdf5_prod
      report  : fsreport
      array   : NetApp25
