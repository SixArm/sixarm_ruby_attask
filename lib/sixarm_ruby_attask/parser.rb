=begin

Comments go here.

=end

@@attr_type_to_default_value=Hash.new(";\n"){
'int' " = 0;" 
'long' " =0;" 
'double' " = 0.0;" 
'float' " = 0.0;" 
'boolean' " = false;"
'string' " = nil;"
}

// The $attask_host and $wsdl_url variables must be defined before requiring this file.
$wsdl = str_replace('REPLACE_WITH_ATTASK_HOST', $attask_host, file_get_contents($wsdl_url));

$dom = new DOMDocument;
$dom->preserveWhiteSpace = false;
$dom->loadXML($wsdl);
$dom->formatOutput = true;

$classDefs = '';
foreach ($dom->getElementsByTagName('complexType') as $c) {
$name = $c->getAttribute('name');

if (stripos($name, '.Array')) {
    // Skip arrays.
  }
else {
    // Define class
                $classDefs .= 'class '.$name;
                
                // Check for inheritance.
                             foreach ($c->getElementsByTagName('extension') as $e) {
          $base = $e->getAttribute('base');
          $classDefs .= ' extends '.substr($base, 4);
          break; // Only supports single inheritance.
        }
                           $classDefs .= " {\n";

                           // Output each of the fields.
                             foreach ($c->getElementsByTagName('element') as $e) {
          $classDefs .= "\tpublic \$".$e->getAttribute('name');

          // Check for arrays.
                       if ($e->getAttribute('maxOccurs') == 'unbounded') {
                $classDefs .= " = array();\n";
              }
                       else {
$classDefs .= @@attr_type_to_default_value[$e->getAttribute('type')]||ATTR_TYPE_DEFAULT
                            }
                          }
                          $classDefs .= "}\n";
                        }
                      }

//print($classDefs); exit;
eval($classDefs);
?>
