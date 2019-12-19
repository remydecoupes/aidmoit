library(geonapi)
library(geometa)
library(uuid)
library(osmdata)

working_dir = getwd()

## Connection to geonetwork
gn <- GNManager$new(
  url = "http://10.0.0.9:8080/geonetwork",
  version = "3.6.1",
  user = "admin",
  pwd = "admin"
  # logger = "DEBUG"
)

## Read input
services <- read.csv(file=paste(working_dir, "../input/datasources.csv", sep = "/"), sep =";")

# Browse datasources and create MD
for (service in services$id) {
  print(paste0("Working on: ", services$datasetName[service]))
  metadata_id <- services$uuid[service]
  # For temporal extent
  ISOMetadataNamespace[["GML"]]$uri <- "http://www.opengis.net/gml"
  
  ## MD creation
  md = ISOMetadata$new()
  metadata_id=paste(metadata_id)
  md$setFileIdentifier(metadata_id)
  md$setCharacterSet("utf8")
  md$setMetadataStandardName("ISO 19115:2003/19139")
  md$setLanguage("eng")
  md$setDateStamp(Sys.time())
  
  ## identification
  ident <- ISODataIdentification$new()
  ident$setAbstract(paste(services$datasetName[service]))
  ident$setLanguage("fra")
  # for (topic in unlist(strsplit(paste(services$topic[service]), ", "))){
  #   ident$addTopicCategory(topic)
  # }
  
  ## keywords
  ### General Keywords
  dynamic_keywords <- ISOKeywords$new()
  for (kw in unlist(strsplit(noquote(paste(services$semantic[service])), ", "))){
    dynamic_keywords$addKeyword(kw)
  }
  ident$addKeywords(dynamic_keywords)
  
    # #add link to data access
    # distrib <- ISODistribution$new()
    # dto <- ISODigitalTransferOptions$new()
    # for (link in unlist(strsplit(paste(services$web.access[service]), ", "))){
    #   # Remove paranthesis
    #   tuple <- gsub('\\(',"",link)
    #   tuple <- gsub('\\)',"",tuple)
    #   newURL <- ISOOnlineResource$new()
    #   newURL$setName(paste0(strsplit(paste(tuple), " @ ")[[1]][1]," :"))
    #   newURL$setLinkage(strsplit(paste(tuple), " @ ")[[1]][2])
    #   newURL$setProtocol("WWW:LINK-1.0-http--link")
    #   dto$addOnlineResource(newURL)
    # }
    # distrib$setDigitalTransferOptions(dto)
    # md$setDistributionInfo(distrib)
    
    # Title and identification
    ct <- ISOCitation$new()
    ct$setTitle(paste(services$datasetName[service]))
    isoid=ISOMetaIdentifier$new(code = services$uuid[service])
    ct$addIdentifier(isoid)
    ident$setCitation(ct)
    ## Aperçu / thumbnail
    # for(thumbnail in unlist(strsplit(paste(services$thumbnail[service]), ", "))){
    #   go <- ISOBrowseGraphic$new(
    #     fileName = thumbnail,
    #     fileDescription = "thumbnail",
    #     fileType = "image/png"
    #   )
    #   ident$addGraphicOverview(go)
    # }
    
    # Temporal Extent
    te <- ISOTemporalExtent$new()
    if (grepl("-", paste(services$temporalExtent[service]) )){
      # start <- ISOdate(paste(services$temporalExtent[service]), 1, 1, 0, 0, 1)
      # end <- ISOdate(paste(services$temporalExtent[service]), 12, 31, 23, 59, 59)
      # tp <- GMLTimePeriod$new(beginPosition = start, endPosition = end)
    }
    else {
      start <- ISOdate(paste(services$temporalExtent[service]), 1, 1, 0, 0, 1)
      end <- ISOdate(paste(services$temporalExtent[service]), 12, 31, 23, 59, 59)
      tp <- GMLTimePeriod$new(beginPosition = start, endPosition = end)
    }
    te$setTimePeriod(tp)
    extent <- ISOExtent$new()
    extent$setTemporalElement(te)
    ident$addExtent(extent)
    
    #Spatial  extent
    extent <- ISOExtent$new()
    bb = getbb(place_name=services$geoExent[service], featuretype = "boundary")
    spatialExtent <- ISOGeographicBoundingBox$new(minx = bb[1,1], miny = bb[2,1], maxx = bb[1,2], maxy = bb[2,2])
    extent$setGeographicElement(spatialExtent)
    ident$addExtent(extent)
    
    md$addIdentificationInfo(ident)

    
    ## Insert or update
    # An update has to be done based on the internal Geonetwork id (that can be queried as well)
    created = gn$insertMetadata(
      xml = md$encode(),
      group = "1",
      category = "dataset"
    )
}
