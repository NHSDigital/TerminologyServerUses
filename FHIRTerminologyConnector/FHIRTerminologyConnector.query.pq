// Use this file to write queries to test your data connector
let
    result = FHIRTerminologyConnector.Contents("https://ontology.nhs.uk/authoring/fhir/CodeSystem/$lookup?system=http://snomed.info/sct&code=56265001&_format=json&property=child")
in
    result