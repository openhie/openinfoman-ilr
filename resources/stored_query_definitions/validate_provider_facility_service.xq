import module namespace csd = "urn:ihe:iti:csd:2013" at "../repo/csd_base_library.xqm";
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
      let $facility_oid := $careServicesRequest/facilities/facility[1]/@oid
      let $service_oid := $careServicesRequest/facilities/facility[1]/service/@oid
	  
      (: if no provider id was provided, then this is invalid. :)
      let $provs0 := if (exists($careServicesRequest/id))
	then csd:filter_by_primary_id(/CSD/providerDirectory/*,$careServicesRequest/id)
      else ()   

      let $provs1 := if (exists($facility_oid) and count($provs0) == 1)
	then 
	   if (count ($provs0[1]/facilities/facility[@oid = $facility_oid]) > 0) then $provs0 else ()
	else $provs0

      let $provs2 := if (exists($service_oid) and count($provs1) == 1)
	then 
	   if (count ($provs1[1]/facilities/facility[@oid = $facility_oid]/service[@oid = $service_oid]) > 0) then $provs1 else ()
	else $provs1

      return if (count($provs2) == 1) then
	<provider oid='{$provs2[1]/@oid}'/>
      else 
	 ()
    }     
  </providerDirectory>
</CSD>
