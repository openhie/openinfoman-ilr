import module namespace csd_bl = "https://github.com/openhie/openinfoman/csd_bl";
declare default element  namespace   "urn:ihe:iti:csd:2013";
declare variable $careServicesRequest as item() external;

(: 
   The query will be executed against the root element of the CSD document.
    
   The dynamic context of this query has $careServicesRequest set to contain any of the search 
   and limit paramaters as sent by the Service Finder
:) 

<CSD xmlns:csd="urn:ihe:iti:csd:2013"  >
  <organizationDirectory/>
  <serviceDirectory/>
  <facilityDirectory/>
  <providerDirectory>
    {
      let $facility_entityID := $careServicesRequest/requestParams/facility[1]/@entityID
      let $service_entityID := $careServicesRequest/requestParams/facility[1]/service[1]/@entityID
	  
      (: if no provider id was provided, then this is invalid. :)
      let $provs0 := if (exists($careServicesRequest/requestParams/id/@entityID))
	then csd_bl:filter_by_primary_id(/CSD/providerDirectory/*,$careServicesRequest/requestParams/id)
      else ()   

      let $provs1 := if (exists($facility_entityID) and count($provs0) = 1)
	then 
	   if (count ($provs0[1]/facilities/facility[@entityID = $facility_entityID]) > 0) then $provs0 else ()
	else $provs0

      let $provs2 := if (exists($service_entityID) and count($provs1) = 1)
	then 
	   if (count ($provs1[1]/facilities/facility[upper-case(@entityID) = upper-case($facility_entityID)]/service[upper-case(@entityID) = upper-case($service_entityID)]) > 0) then $provs1 else ()
	else $provs1

      return if (count($provs2) = 1) then
	<provider entityID='{$provs2[1]/@entityID}'/>
      else 
	 ()
    }     
  </providerDirectory>
</CSD>
