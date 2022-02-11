<#PSScriptInfo
. REFERENCIA
#>

## Esta función recibe un nombre de fichero INI + una seccion
## Devuelve un objeto de tipo array con los valores de seccion

Function loadConfig ($fileName, $oneSection) {
    $config = Get-Content ($fileName)    
    $cfg = @{}
    $sec = $cfg
    $section = ''
    ForEach ($line in $config) {
       $line = $line.Trim()
       if ($line.startswith('[')) {
          $section = $line.replace('[','').replace(']','')
          if ($oneSection -eq '*') {
             $cfg.Add($section,@{})
             $sec = $cfg.$section
          }   
          continue
       }       
       if ($oneSection -ne $null -and $section -ne $oneSection -and $oneSection -ne '*') {continue}
       $k = $line.IndexOf('=')
       if ($line -eq '' -or $k -lt 1 -or $line[0] -in '[','#') {continue}
       $sec.Add($line.Substring(0,$k), $line.Substring($k+1))
    }
    Return $cfg
 }