# =============================================================================
# ProyectoOllin2026 — Creación de campos y objetos faltantes
# Genera todos los archivos .field-meta.xml y .object-meta.xml requeridos
# para cubrir el documento de estructura de datos del cliente.
#
# Uso:
#   .\scripts\setup_campos_faltantes.ps1                  → crea archivos + despliega
#   .\scripts\setup_campos_faltantes.ps1 --solo-archivos  → solo crea archivos, sin deploy
# =============================================================================

param(
    [switch]$SoloArchivos
)

$OBJECTS_PATH = "force-app/main/default/objects"
$DEPLOY = -not $SoloArchivos
$script:CREATED = 0
$script:SKIPPED = 0

function Write-Section($title) {
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Blue
    Write-Host "  $title" -ForegroundColor Blue
    Write-Host "==================================================" -ForegroundColor Blue
}

function Write-Field($obj, $name, $xml) {
    $dir = "$OBJECTS_PATH/$obj/fields"
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $file = "$dir/$name.field-meta.xml"
    if (-not (Test-Path $file)) {
        $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($xml)
        [System.IO.File]::WriteAllBytes($file, $bytes)
        Write-Host "  OK  $obj  >  $name" -ForegroundColor Green
        $script:CREATED++
    } else {
        Write-Host "  --  $obj  >  $name (ya existe)" -ForegroundColor Yellow
        $script:SKIPPED++
    }
}

function Write-Object($name, $xml) {
    $dir = "$OBJECTS_PATH/$name"
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $file = "$dir/$name.object-meta.xml"
    if (-not (Test-Path $file)) {
        $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($xml)
        [System.IO.File]::WriteAllBytes($file, $bytes)
        Write-Host "  OK  Objeto creado: $name" -ForegroundColor Green
        $script:CREATED++
    } else {
        Write-Host "  --  Objeto: $name (ya existe)" -ForegroundColor Yellow
        $script:SKIPPED++
    }
}

# =============================================================================
# 1 · Tech_Seguro__c
# =============================================================================
Write-Section "1 · Tech_Seguro__c  (le faltan ~18 campos)"

Write-Field "Tech_Seguro__c" "Ramo__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Ramo__c</fullName>
    <label>Ramo</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Picklist</type>
    <valueSet>
        <restricted>true</restricted>
        <valueSetDefinition>
            <sorted>false</sorted>
            <value><fullName>Auto</fullName><default>false</default><label>Auto</label></value>
            <value><fullName>GMM</fullName><default>false</default><label>GMM</label></value>
            <value><fullName>Vida</fullName><default>false</default><label>Vida</label></value>
            <value><fullName>PPR</fullName><default>false</default><label>PPR</label></value>
            <value><fullName>Daños</fullName><default>false</default><label>Daños</label></value>
            <value><fullName>RC</fullName><default>false</default><label>RC</label></value>
            <value><fullName>Membresía Salud</fullName><default>false</default><label>Membresía Salud</label></value>
            <value><fullName>Fianzas</fullName><default>false</default><label>Fianzas</label></value>
        </valueSetDefinition>
    </valueSet>
</CustomField>
'@

Write-Field "Tech_Seguro__c" "Subproducto__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Subproducto__c</fullName>
    <label>Subproducto</label>
    <length>120</length>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Text</type>
    <unique>false</unique>
</CustomField>
'@

Write-Field "Tech_Seguro__c" "Estatus__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Estatus__c</fullName>
    <label>Estatus</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Picklist</type>
    <valueSet>
        <restricted>true</restricted>
        <valueSetDefinition>
            <sorted>false</sorted>
            <value><fullName>Emitida</fullName><default>true</default><label>Emitida</label></value>
            <value><fullName>Vigente</fullName><default>false</default><label>Vigente</label></value>
            <value><fullName>Por renovar</fullName><default>false</default><label>Por renovar</label></value>
            <value><fullName>Renovada</fullName><default>false</default><label>Renovada</label></value>
            <value><fullName>Vencida</fullName><default>false</default><label>Vencida</label></value>
            <value><fullName>Cancelada</fullName><default>false</default><label>Cancelada</label></value>
        </valueSetDefinition>
    </valueSet>
</CustomField>
'@

Write-Field "Tech_Seguro__c" "Inicio_del_seguro__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Inicio_del_seguro__c</fullName>
    <label>Inicio del seguro</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Date</type>
</CustomField>
'@

Write-Field "Tech_Seguro__c" "Fin_del_seguro__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Fin_del_seguro__c</fullName>
    <label>Fin del seguro</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Date</type>
</CustomField>
'@

Write-Field "Tech_Seguro__c" "Frecuencia_de_pago__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Frecuencia_de_pago__c</fullName>
    <label>Frecuencia de pago</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Picklist</type>
    <valueSet>
        <restricted>true</restricted>
        <valueSetDefinition>
            <sorted>false</sorted>
            <value><fullName>Contado</fullName><default>false</default><label>Contado</label></value>
            <value><fullName>Mensual</fullName><default>false</default><label>Mensual</label></value>
            <value><fullName>Trimestral</fullName><default>false</default><label>Trimestral</label></value>
            <value><fullName>Semestral</fullName><default>false</default><label>Semestral</label></value>
            <value><fullName>Anual</fullName><default>false</default><label>Anual</label></value>
        </valueSetDefinition>
    </valueSet>
</CustomField>
'@

Write-Field "Tech_Seguro__c" "Forma_de_pago__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Forma_de_pago__c</fullName>
    <label>Forma de pago</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Picklist</type>
    <valueSet>
        <restricted>true</restricted>
        <valueSetDefinition>
            <sorted>false</sorted>
            <value><fullName>Tarjeta</fullName><default>false</default><label>Tarjeta</label></value>
            <value><fullName>Transferencia</fullName><default>false</default><label>Transferencia</label></value>
            <value><fullName>Efectivo</fullName><default>false</default><label>Efectivo</label></value>
            <value><fullName>Domiciliación</fullName><default>false</default><label>Domiciliación</label></value>
        </valueSetDefinition>
    </valueSet>
</CustomField>
'@

Write-Field "Tech_Seguro__c" "Prima_neta__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Prima_neta__c</fullName>
    <label>Prima neta</label>
    <precision>18</precision>
    <required>false</required>
    <scale>2</scale>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Currency</type>
</CustomField>
'@

Write-Field "Tech_Seguro__c" "Descuento__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Descuento__c</fullName>
    <label>Descuento</label>
    <precision>18</precision>
    <required>false</required>
    <scale>2</scale>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Currency</type>
</CustomField>
'@

Write-Field "Tech_Seguro__c" "Recargos__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Recargos__c</fullName>
    <label>Recargos</label>
    <precision>18</precision>
    <required>false</required>
    <scale>2</scale>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Currency</type>
</CustomField>
'@

Write-Field "Tech_Seguro__c" "Derechos__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Derechos__c</fullName>
    <label>Derechos</label>
    <precision>18</precision>
    <required>false</required>
    <scale>2</scale>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Currency</type>
</CustomField>
'@

Write-Field "Tech_Seguro__c" "IVA__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>IVA__c</fullName>
    <label>IVA</label>
    <precision>18</precision>
    <required>false</required>
    <scale>2</scale>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Currency</type>
</CustomField>
'@

Write-Field "Tech_Seguro__c" "Ajuste__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Ajuste__c</fullName>
    <label>Ajuste</label>
    <precision>18</precision>
    <required>false</required>
    <scale>2</scale>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Currency</type>
</CustomField>
'@

Write-Field "Tech_Seguro__c" "Prima_total__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Prima_total__c</fullName>
    <externalId>false</externalId>
    <formula>Prima_neta__c - Descuento__c + Recargos__c + Derechos__c + IVA__c + Ajuste__c</formula>
    <formulaTreatBlanksAs>BlankAsZero</formulaTreatBlanksAs>
    <label>Prima total</label>
    <precision>18</precision>
    <required>false</required>
    <scale>2</scale>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Currency</type>
</CustomField>
'@

Write-Field "Tech_Seguro__c" "Canal__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Canal__c</fullName>
    <label>Canal</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Picklist</type>
    <valueSet>
        <restricted>true</restricted>
        <valueSetDefinition>
            <sorted>false</sorted>
            <value><fullName>Digital</fullName><default>false</default><label>Digital</label></value>
            <value><fullName>Consultivo</fullName><default>false</default><label>Consultivo</label></value>
            <value><fullName>Promotoría</fullName><default>false</default><label>Promotoría</label></value>
        </valueSetDefinition>
    </valueSet>
</CustomField>
'@

Write-Field "Tech_Seguro__c" "Tipo_originador__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Tipo_originador__c</fullName>
    <label>Tipo originador</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Picklist</type>
    <valueSet>
        <restricted>true</restricted>
        <valueSetDefinition>
            <sorted>false</sorted>
            <value><fullName>Humano</fullName><default>false</default><label>Humano</label></value>
            <value><fullName>IA</fullName><default>false</default><label>IA</label></value>
            <value><fullName>Externo</fullName><default>false</default><label>Externo</label></value>
        </valueSetDefinition>
    </valueSet>
</CustomField>
'@

Write-Field "Tech_Seguro__c" "Dias_para_vencer__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Dias_para_vencer__c</fullName>
    <externalId>false</externalId>
    <formula>IF(ISNULL(Fin_del_seguro__c), NULL, Fin_del_seguro__c - TODAY())</formula>
    <formulaTreatBlanksAs>BlankAsZero</formulaTreatBlanksAs>
    <label>Días para vencer</label>
    <precision>18</precision>
    <required>false</required>
    <scale>0</scale>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Number</type>
</CustomField>
'@

Write-Field "Tech_Seguro__c" "Pct_Comision__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Pct_Comision__c</fullName>
    <label>% Comisión</label>
    <precision>5</precision>
    <required>false</required>
    <scale>2</scale>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Percent</type>
</CustomField>
'@

Write-Field "Tech_Seguro__c" "Monto_Comision__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Monto_Comision__c</fullName>
    <label>Monto comisión</label>
    <precision>18</precision>
    <required>false</required>
    <scale>2</scale>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Currency</type>
</CustomField>
'@

Write-Field "Tech_Seguro__c" "Semaforo_renovacion__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Semaforo_renovacion__c</fullName>
    <label>Semáforo renovación</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Picklist</type>
    <valueSet>
        <restricted>true</restricted>
        <valueSetDefinition>
            <sorted>false</sorted>
            <value><fullName>Verde</fullName><default>false</default><label>Verde</label></value>
            <value><fullName>Amarillo</fullName><default>false</default><label>Amarillo</label></value>
            <value><fullName>Rojo</fullName><default>false</default><label>Rojo</label></value>
        </valueSetDefinition>
    </valueSet>
</CustomField>
'@


# =============================================================================
# 2 · Tech_Fianza__c
# =============================================================================
Write-Section "2 · Tech_Fianza__c  (le faltan ~12 campos)"

Write-Field "Tech_Fianza__c" "Contrato__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Contrato__c</fullName>
    <label>Contrato</label>
    <referenceTo>Contract</referenceTo>
    <relationshipLabel>Fianzas</relationshipLabel>
    <relationshipName>Fianzas_Tech</relationshipName>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Lookup</type>
</CustomField>
'@

Write-Field "Tech_Fianza__c" "Tipo_de_Riesgo__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Tipo_de_Riesgo__c</fullName>
    <label>Tipo de riesgo</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Picklist</type>
    <valueSet>
        <restricted>true</restricted>
        <valueSetDefinition>
            <sorted>false</sorted>
            <value><fullName>Cumplimiento</fullName><default>false</default><label>Cumplimiento</label></value>
            <value><fullName>Anticipo</fullName><default>false</default><label>Anticipo</label></value>
            <value><fullName>Vicios y Defectos Ocultos</fullName><default>false</default><label>Vicios y Defectos Ocultos</label></value>
            <value><fullName>Pasivos Laborales</fullName><default>false</default><label>Pasivos Laborales</label></value>
            <value><fullName>Otro</fullName><default>false</default><label>Otro</label></value>
        </valueSetDefinition>
    </valueSet>
</CustomField>
'@

Write-Field "Tech_Fianza__c" "Fecha_de_Emision__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Fecha_de_Emision__c</fullName>
    <label>Fecha de emisión</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Date</type>
</CustomField>
'@

Write-Field "Tech_Fianza__c" "Fecha_de_Vencimiento__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Fecha_de_Vencimiento__c</fullName>
    <label>Fecha de vencimiento (original)</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Date</type>
</CustomField>
'@

Write-Field "Tech_Fianza__c" "Monto_Afianzado__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Monto_Afianzado__c</fullName>
    <label>Monto afianzado (original)</label>
    <precision>18</precision>
    <required>false</required>
    <scale>2</scale>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Currency</type>
</CustomField>
'@

Write-Field "Tech_Fianza__c" "Prima_neta__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Prima_neta__c</fullName>
    <label>Prima neta (original)</label>
    <precision>18</precision>
    <required>false</required>
    <scale>2</scale>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Currency</type>
</CustomField>
'@

Write-Field "Tech_Fianza__c" "Monto_Afianzado_Vigente__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Monto_Afianzado_Vigente__c</fullName>
    <label>Monto afianzado vigente</label>
    <precision>18</precision>
    <required>false</required>
    <scale>2</scale>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Currency</type>
</CustomField>
'@

Write-Field "Tech_Fianza__c" "Prima_Vigente__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Prima_Vigente__c</fullName>
    <label>Prima vigente</label>
    <precision>18</precision>
    <required>false</required>
    <scale>2</scale>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Currency</type>
</CustomField>
'@

Write-Field "Tech_Fianza__c" "Fecha_Vencimiento_Vigente__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Fecha_Vencimiento_Vigente__c</fullName>
    <label>Fecha vencimiento vigente</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Date</type>
</CustomField>
'@

Write-Field "Tech_Fianza__c" "Dias_para_vencer__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Dias_para_vencer__c</fullName>
    <externalId>false</externalId>
    <formula>IF(ISNULL(Fecha_Vencimiento_Vigente__c), NULL, Fecha_Vencimiento_Vigente__c - TODAY())</formula>
    <formulaTreatBlanksAs>BlankAsZero</formulaTreatBlanksAs>
    <label>Días para vencer</label>
    <precision>18</precision>
    <required>false</required>
    <scale>0</scale>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Number</type>
</CustomField>
'@

Write-Field "Tech_Fianza__c" "Exposicion__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Exposicion__c</fullName>
    <label>Exposición %</label>
    <precision>5</precision>
    <required>false</required>
    <scale>2</scale>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Percent</type>
</CustomField>
'@

Write-Field "Tech_Fianza__c" "Vendedor__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Vendedor__c</fullName>
    <label>Vendedor</label>
    <referenceTo>Tech_Vendedor__c</referenceTo>
    <relationshipLabel>Fianzas</relationshipLabel>
    <relationshipName>Fianzas_Vendedor</relationshipName>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Lookup</type>
</CustomField>
'@


# =============================================================================
# 3 · Tech_Endoso__c — campos faltantes (dual: Seguro y Fianza)
# =============================================================================
Write-Section "3 · Tech_Endoso__c  (faltan 2 campos — objeto dual Seguro + Fianza)"

Write-Field "Tech_Endoso__c" "Fecha_efectiva__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Fecha_efectiva__c</fullName>
    <label>Fecha efectiva</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Date</type>
</CustomField>
'@

Write-Field "Tech_Endoso__c" "Diferencia_monto__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Diferencia_monto__c</fullName>
    <label>Diferencia monto</label>
    <precision>18</precision>
    <required>false</required>
    <scale>2</scale>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Currency</type>
</CustomField>
'@


# =============================================================================
# 4 · Tech_Plan_de_Pago__c — campos de domiciliación faltantes
# =============================================================================
Write-Section "4 · Tech_Plan_de_Pago__c  (faltan 5 campos — domiciliación)"

Write-Field "Tech_Plan_de_Pago__c" "Monto_total__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Monto_total__c</fullName>
    <label>Monto total</label>
    <precision>18</precision>
    <required>false</required>
    <scale>2</scale>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Currency</type>
</CustomField>
'@

Write-Field "Tech_Plan_de_Pago__c" "Dia_cobro_mensual__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Dia_cobro_mensual__c</fullName>
    <label>Día de cobro mensual</label>
    <precision>2</precision>
    <required>false</required>
    <scale>0</scale>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Number</type>
</CustomField>
'@

Write-Field "Tech_Plan_de_Pago__c" "Domiciliacion_activa__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Domiciliacion_activa__c</fullName>
    <defaultValue>false</defaultValue>
    <label>Domiciliación activa</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Checkbox</type>
</CustomField>
'@

Write-Field "Tech_Plan_de_Pago__c" "Ultimos_4_digitos__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Ultimos_4_digitos__c</fullName>
    <label>Últimos 4 dígitos</label>
    <length>4</length>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Text</type>
    <unique>false</unique>
</CustomField>
'@

Write-Field "Tech_Plan_de_Pago__c" "Referencia_domiciliacion__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Referencia_domiciliacion__c</fullName>
    <label>Referencia domiciliación</label>
    <length>100</length>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Text</type>
    <unique>false</unique>
</CustomField>
'@


# =============================================================================
# 5 · Tech_Vendedor__c — campos de perfil comercial faltantes
# =============================================================================
Write-Section "5 · Tech_Vendedor__c  (faltan 5 campos)"

Write-Field "Tech_Vendedor__c" "Zona__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Zona__c</fullName>
    <label>Zona</label>
    <length>100</length>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Text</type>
    <unique>false</unique>
</CustomField>
'@

Write-Field "Tech_Vendedor__c" "Promotoria__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Promotoria__c</fullName>
    <label>Promotoría</label>
    <length>100</length>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Text</type>
    <unique>false</unique>
</CustomField>
'@

Write-Field "Tech_Vendedor__c" "Porcentaje_Comision_Ollin__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Porcentaje_Comision_Ollin__c</fullName>
    <label>% Comisión sobre Ollin</label>
    <precision>5</precision>
    <required>false</required>
    <scale>2</scale>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Percent</type>
</CustomField>
'@

Write-Field "Tech_Vendedor__c" "Fecha_Inicio__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Fecha_Inicio__c</fullName>
    <label>Fecha de inicio</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Date</type>
</CustomField>
'@

Write-Field "Tech_Vendedor__c" "Carga_Trabajo__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Carga_Trabajo__c</fullName>
    <label>Carga de trabajo</label>
    <precision>4</precision>
    <required>false</required>
    <scale>0</scale>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Number</type>
</CustomField>
'@


# =============================================================================
# 6 · Tech_Recibo_Pago__c — campos de pago parcial faltantes
# =============================================================================
Write-Section "6 · Tech_Recibo_Pago__c  (faltan 3 campos)"

Write-Field "Tech_Recibo_Pago__c" "Monto_cobrado__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Monto_cobrado__c</fullName>
    <label>Monto cobrado</label>
    <precision>18</precision>
    <required>false</required>
    <scale>2</scale>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Currency</type>
</CustomField>
'@

Write-Field "Tech_Recibo_Pago__c" "Saldo__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Saldo__c</fullName>
    <externalId>false</externalId>
    <formula>Monto_programado__c - IF(ISNULL(Monto_cobrado__c), 0, Monto_cobrado__c)</formula>
    <formulaTreatBlanksAs>BlankAsZero</formulaTreatBlanksAs>
    <label>Saldo pendiente</label>
    <precision>18</precision>
    <required>false</required>
    <scale>2</scale>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Currency</type>
</CustomField>
'@

Write-Field "Tech_Recibo_Pago__c" "Referencia_pago__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Referencia_pago__c</fullName>
    <label>Referencia de pago</label>
    <length>100</length>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Text</type>
    <unique>false</unique>
</CustomField>
'@


# =============================================================================
# 7 · Tech_Convenio_Modificatorio__c — número autonumérico
# =============================================================================
Write-Section "7 · Tech_Convenio_Modificatorio__c  (falta 1 campo)"

Write-Field "Tech_Convenio_Modificatorio__c" "Numero_Convenio__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Numero_Convenio__c</fullName>
    <displayFormat>CONV-{0000}</displayFormat>
    <externalId>false</externalId>
    <label>Número de convenio</label>
    <required>false</required>
    <startingNumber>1</startingNumber>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>AutoNumber</type>
</CustomField>
'@


# =============================================================================
# 8 · NUEVO OBJETO: Tech_Comision__c
# =============================================================================
Write-Section "8 · NUEVO OBJETO: Tech_Comision__c  (capa de comisiones)"

Write-Object "Tech_Comision__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <allowInChatterGroups>false</allowInChatterGroups>
    <compactLayoutAssignment>SYSTEM</compactLayoutAssignment>
    <deploymentStatus>Deployed</deploymentStatus>
    <enableActivities>false</enableActivities>
    <enableBulkApi>true</enableBulkApi>
    <enableFeeds>false</enableFeeds>
    <enableHistory>false</enableHistory>
    <enableLicensing>false</enableLicensing>
    <enableReports>true</enableReports>
    <enableSearch>true</enableSearch>
    <enableSharing>true</enableSharing>
    <enableStreamingApi>true</enableStreamingApi>
    <externalSharingModel>Private</externalSharingModel>
    <label>Tech Comision</label>
    <nameField>
        <displayFormat>COM-{0000}</displayFormat>
        <label>Número de comisión</label>
        <trackHistory>false</trackHistory>
        <type>AutoNumber</type>
    </nameField>
    <pluralLabel>Tech Comisiones</pluralLabel>
    <searchLayouts></searchLayouts>
    <sharingModel>ReadWrite</sharingModel>
    <visibility>Public</visibility>
</CustomObject>
'@

Write-Field "Tech_Comision__c" "Seguro__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Seguro__c</fullName>
    <label>Seguro</label>
    <referenceTo>Tech_Seguro__c</referenceTo>
    <relationshipLabel>Comisiones</relationshipLabel>
    <relationshipName>Comisiones_Seguro</relationshipName>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Lookup</type>
</CustomField>
'@

Write-Field "Tech_Comision__c" "Fianza__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Fianza__c</fullName>
    <label>Fianza</label>
    <referenceTo>Tech_Fianza__c</referenceTo>
    <relationshipLabel>Comisiones</relationshipLabel>
    <relationshipName>Comisiones_Fianza</relationshipName>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Lookup</type>
</CustomField>
'@

Write-Field "Tech_Comision__c" "Vendedor__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Vendedor__c</fullName>
    <label>Vendedor</label>
    <referenceTo>Tech_Vendedor__c</referenceTo>
    <relationshipLabel>Comisiones</relationshipLabel>
    <relationshipName>Comisiones_Vendedor</relationshipName>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Lookup</type>
</CustomField>
'@

Write-Field "Tech_Comision__c" "Pct_Aplicado__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Pct_Aplicado__c</fullName>
    <label>% Aplicado (snapshot)</label>
    <precision>5</precision>
    <required>false</required>
    <scale>2</scale>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Percent</type>
</CustomField>
'@

Write-Field "Tech_Comision__c" "Monto_Ollin__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Monto_Ollin__c</fullName>
    <label>Monto Ollin</label>
    <precision>18</precision>
    <required>false</required>
    <scale>2</scale>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Currency</type>
</CustomField>
'@

Write-Field "Tech_Comision__c" "Monto_Vendedor__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Monto_Vendedor__c</fullName>
    <label>Monto vendedor</label>
    <precision>18</precision>
    <required>false</required>
    <scale>2</scale>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Currency</type>
</CustomField>
'@

Write-Field "Tech_Comision__c" "Estatus__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Estatus__c</fullName>
    <label>Estatus</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Picklist</type>
    <valueSet>
        <restricted>true</restricted>
        <valueSetDefinition>
            <sorted>false</sorted>
            <value><fullName>Devengada</fullName><default>true</default><label>Devengada</label></value>
            <value><fullName>Liberada</fullName><default>false</default><label>Liberada</label></value>
            <value><fullName>Pagada</fullName><default>false</default><label>Pagada</label></value>
            <value><fullName>Revertida</fullName><default>false</default><label>Revertida (clawback)</label></value>
        </valueSetDefinition>
    </valueSet>
</CustomField>
'@

Write-Field "Tech_Comision__c" "Tabla_Comision__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Tabla_Comision__c</fullName>
    <label>Tabla de comisiones</label>
    <referenceTo>Tabla_Comision__c</referenceTo>
    <relationshipLabel>Comisiones generadas</relationshipLabel>
    <relationshipName>Comisiones_Tabla</relationshipName>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Lookup</type>
</CustomField>
'@


# =============================================================================
# 9 · NUEVO OBJETO: EjecutivoContacto__c
# =============================================================================
Write-Section "9 · NUEVO OBJETO: EjecutivoContacto__c  (hijo M-D de Institucion__c)"

Write-Object "EjecutivoContacto__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <allowInChatterGroups>false</allowInChatterGroups>
    <compactLayoutAssignment>SYSTEM</compactLayoutAssignment>
    <deploymentStatus>Deployed</deploymentStatus>
    <enableActivities>false</enableActivities>
    <enableBulkApi>true</enableBulkApi>
    <enableFeeds>false</enableFeeds>
    <enableHistory>false</enableHistory>
    <enableLicensing>false</enableLicensing>
    <enableReports>true</enableReports>
    <enableSearch>true</enableSearch>
    <enableSharing>true</enableSharing>
    <enableStreamingApi>true</enableStreamingApi>
    <externalSharingModel>ControlledByParent</externalSharingModel>
    <label>Ejecutivo de Contacto</label>
    <nameField>
        <label>Nombre completo</label>
        <trackHistory>false</trackHistory>
        <type>Text</type>
    </nameField>
    <pluralLabel>Ejecutivos de Contacto</pluralLabel>
    <searchLayouts></searchLayouts>
    <sharingModel>ControlledByParent</sharingModel>
    <visibility>Public</visibility>
</CustomObject>
'@

Write-Field "EjecutivoContacto__c" "Institucion__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Institucion__c</fullName>
    <label>Institución</label>
    <referenceTo>Institucion__c</referenceTo>
    <relationshipLabel>Ejecutivos de Contacto</relationshipLabel>
    <relationshipName>Ejecutivos_de_Contacto</relationshipName>
    <relationshipOrder>0</relationshipOrder>
    <required>true</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>MasterDetail</type>
</CustomField>
'@

Write-Field "EjecutivoContacto__c" "Puesto__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Puesto__c</fullName>
    <label>Puesto</label>
    <length>120</length>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Text</type>
    <unique>false</unique>
</CustomField>
'@

Write-Field "EjecutivoContacto__c" "Area__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Area__c</fullName>
    <label>Área</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Picklist</type>
    <valueSet>
        <restricted>true</restricted>
        <valueSetDefinition>
            <sorted>false</sorted>
            <value><fullName>Suscripción</fullName><default>false</default><label>Suscripción</label></value>
            <value><fullName>Siniestros</fullName><default>false</default><label>Siniestros</label></value>
            <value><fullName>Fianzas</fullName><default>false</default><label>Fianzas</label></value>
            <value><fullName>Comercial</fullName><default>false</default><label>Comercial</label></value>
            <value><fullName>Operaciones</fullName><default>false</default><label>Operaciones</label></value>
            <value><fullName>Dirección</fullName><default>false</default><label>Dirección</label></value>
        </valueSetDefinition>
    </valueSet>
</CustomField>
'@

Write-Field "EjecutivoContacto__c" "Es_Contacto_Principal__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Es_Contacto_Principal__c</fullName>
    <defaultValue>false</defaultValue>
    <label>Es contacto principal</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Checkbox</type>
</CustomField>
'@

Write-Field "EjecutivoContacto__c" "Email__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Email__c</fullName>
    <label>Email</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Email</type>
    <unique>false</unique>
</CustomField>
'@

Write-Field "EjecutivoContacto__c" "Telefono__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Telefono__c</fullName>
    <label>Teléfono directo</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Phone</type>
</CustomField>
'@

Write-Field "EjecutivoContacto__c" "Celular__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Celular__c</fullName>
    <label>Celular</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Phone</type>
</CustomField>
'@


# =============================================================================
# 10 · Lead — campos custom para Flujo de Ventas
# =============================================================================
Write-Section "10 · Lead  (objeto estándar — campos custom del Flujo de Ventas)"

Write-Field "Lead" "Score__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Score__c</fullName>
    <label>Score de calificación</label>
    <precision>3</precision>
    <required>false</required>
    <scale>0</scale>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Number</type>
</CustomField>
'@

Write-Field "Lead" "Puede_Reactivarse__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Puede_Reactivarse__c</fullName>
    <defaultValue>false</defaultValue>
    <label>Puede reactivarse</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Checkbox</type>
</CustomField>
'@

Write-Field "Lead" "Origen_Lead__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Origen_Lead__c</fullName>
    <label>Origen del lead</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Picklist</type>
    <valueSet>
        <restricted>true</restricted>
        <valueSetDefinition>
            <sorted>false</sorted>
            <value><fullName>Web</fullName><default>false</default><label>Web (Muévete Seguro)</label></value>
            <value><fullName>Referido</fullName><default>false</default><label>Referido</label></value>
            <value><fullName>Llamada</fullName><default>false</default><label>Llamada</label></value>
            <value><fullName>Redes Sociales</fullName><default>false</default><label>Redes Sociales</label></value>
            <value><fullName>Campaña</fullName><default>false</default><label>Campaña</label></value>
        </valueSetDefinition>
    </valueSet>
</CustomField>
'@

Write-Field "Lead" "Motivo_No_Calificacion__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Motivo_No_Calificacion__c</fullName>
    <label>Motivo no calificación</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Picklist</type>
    <valueSet>
        <restricted>false</restricted>
        <valueSetDefinition>
            <sorted>false</sorted>
            <value><fullName>Sin información suficiente</fullName><default>false</default><label>Sin información suficiente</label></value>
            <value><fullName>No aplica producto</fullName><default>false</default><label>No aplica al producto</label></value>
            <value><fullName>Duplicado</fullName><default>false</default><label>Duplicado</label></value>
            <value><fullName>Sin interés</fullName><default>false</default><label>Sin interés</label></value>
            <value><fullName>Otro</fullName><default>false</default><label>Otro</label></value>
        </valueSetDefinition>
    </valueSet>
</CustomField>
'@


# =============================================================================
# 11 · Opportunity — campos custom para Flujo de Ventas
# =============================================================================
Write-Section "11 · Opportunity  (objeto estándar — campos custom del Flujo de Ventas)"

Write-Field "Opportunity" "Ramo__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Ramo__c</fullName>
    <label>Ramo</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Picklist</type>
    <valueSet>
        <restricted>true</restricted>
        <valueSetDefinition>
            <sorted>false</sorted>
            <value><fullName>Auto</fullName><default>false</default><label>Auto</label></value>
            <value><fullName>GMM</fullName><default>false</default><label>GMM</label></value>
            <value><fullName>Vida</fullName><default>false</default><label>Vida</label></value>
            <value><fullName>PPR</fullName><default>false</default><label>PPR</label></value>
            <value><fullName>Daños</fullName><default>false</default><label>Daños</label></value>
            <value><fullName>RC</fullName><default>false</default><label>RC</label></value>
            <value><fullName>Membresía Salud</fullName><default>false</default><label>Membresía Salud</label></value>
            <value><fullName>Fianzas</fullName><default>false</default><label>Fianzas</label></value>
        </valueSetDefinition>
    </valueSet>
</CustomField>
'@

Write-Field "Opportunity" "Subproducto__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Subproducto__c</fullName>
    <label>Subproducto</label>
    <length>120</length>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Text</type>
    <unique>false</unique>
</CustomField>
'@

Write-Field "Opportunity" "Vendedor__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Vendedor__c</fullName>
    <label>Vendedor</label>
    <referenceTo>Tech_Vendedor__c</referenceTo>
    <relationshipLabel>Oportunidades</relationshipLabel>
    <relationshipName>Oportunidades_Vendedor</relationshipName>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Lookup</type>
</CustomField>
'@

Write-Field "Opportunity" "Tipo_Originador__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Tipo_Originador__c</fullName>
    <label>Tipo originador</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Picklist</type>
    <valueSet>
        <restricted>true</restricted>
        <valueSetDefinition>
            <sorted>false</sorted>
            <value><fullName>Digital</fullName><default>false</default><label>Digital</label></value>
            <value><fullName>Consultivo</fullName><default>false</default><label>Consultivo</label></value>
            <value><fullName>Promotoría</fullName><default>false</default><label>Promotoría</label></value>
        </valueSetDefinition>
    </valueSet>
</CustomField>
'@

Write-Field "Opportunity" "Motivo_Cierre_Perdido__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Motivo_Cierre_Perdido__c</fullName>
    <label>Motivo cierre perdido</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Picklist</type>
    <valueSet>
        <restricted>false</restricted>
        <valueSetDefinition>
            <sorted>false</sorted>
            <value><fullName>Precio</fullName><default>false</default><label>Precio</label></value>
            <value><fullName>Competencia</fullName><default>false</default><label>Competencia</label></value>
            <value><fullName>No calificó</fullName><default>false</default><label>No calificó</label></value>
            <value><fullName>No interesado</fullName><default>false</default><label>No interesado</label></value>
            <value><fullName>Sin respuesta</fullName><default>false</default><label>Sin respuesta</label></value>
            <value><fullName>Otro</fullName><default>false</default><label>Otro</label></value>
        </valueSetDefinition>
    </valueSet>
</CustomField>
'@

Write-Field "Opportunity" "Aseguradora_Competidora__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Aseguradora_Competidora__c</fullName>
    <label>Aseguradora competidora</label>
    <length>120</length>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Text</type>
    <unique>false</unique>
</CustomField>
'@

Write-Field "Opportunity" "Puede_Reactivarse__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Puede_Reactivarse__c</fullName>
    <defaultValue>false</defaultValue>
    <label>Puede reactivarse (reciclaje)</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Checkbox</type>
</CustomField>
'@

Write-Field "Opportunity" "Notas_Vendedor__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Notas_Vendedor__c</fullName>
    <label>Notas del vendedor</label>
    <length>5000</length>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>LongTextArea</type>
    <visibleLines>4</visibleLines>
</CustomField>
'@


# =============================================================================
# 12 · Contract — campos custom para módulo Fianzas
# =============================================================================
Write-Section "12 · Contract  (objeto estándar — padre de Tech_Fianza__c y Convenio)"

Write-Field "Contract" "Vendedor__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Vendedor__c</fullName>
    <label>Vendedor</label>
    <referenceTo>Tech_Vendedor__c</referenceTo>
    <relationshipLabel>Contratos</relationshipLabel>
    <relationshipName>Contratos_Vendedor</relationshipName>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Lookup</type>
</CustomField>
'@

Write-Field "Contract" "Contratista__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Contratista__c</fullName>
    <label>Contratista</label>
    <referenceTo>Account</referenceTo>
    <relationshipLabel>Contratos (Contratista)</relationshipLabel>
    <relationshipName>Contratos_Contratista</relationshipName>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Lookup</type>
</CustomField>
'@

Write-Field "Contract" "Beneficiario__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Beneficiario__c</fullName>
    <label>Beneficiario</label>
    <referenceTo>Account</referenceTo>
    <relationshipLabel>Contratos (Beneficiario)</relationshipLabel>
    <relationshipName>Contratos_Beneficiario</relationshipName>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Lookup</type>
</CustomField>
'@

Write-Field "Contract" "Institucion__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Institucion__c</fullName>
    <label>Institución (Afianzadora)</label>
    <referenceTo>Institucion__c</referenceTo>
    <relationshipLabel>Contratos</relationshipLabel>
    <relationshipName>Contratos_Institucion</relationshipName>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Lookup</type>
</CustomField>
'@

Write-Field "Contract" "Valor_Contrato_Vigente__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Valor_Contrato_Vigente__c</fullName>
    <label>Valor contrato vigente</label>
    <precision>18</precision>
    <required>false</required>
    <scale>2</scale>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Currency</type>
</CustomField>
'@

Write-Field "Contract" "Fin_Contrato_Vigente__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Fin_Contrato_Vigente__c</fullName>
    <label>Fin contrato vigente</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Date</type>
</CustomField>
'@

Write-Field "Contract" "Suma_Fianzas__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Suma_Fianzas__c</fullName>
    <label>Suma de fianzas vigentes</label>
    <precision>18</precision>
    <required>false</required>
    <scale>2</scale>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Currency</type>
</CustomField>
'@

Write-Field "Contract" "Exposicion_del__c" @'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Exposicion_del__c</fullName>
    <label>Exposición %</label>
    <precision>5</precision>
    <required>false</required>
    <scale>2</scale>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Percent</type>
</CustomField>
'@


# =============================================================================
# PERMISOS DE CAMPO EN PERFILES
# Agrega fieldPermissions (editable + readable) para todos los campos nuevos
# en cada profile que exista en el proyecto.
# Los campos de fórmula solo reciben readable=true.
# =============================================================================
Write-Section "13 · Permisos de campo en todos los perfiles"

# Campos de fórmula (solo readable)
$formulaFields = @(
    'Tech_Seguro__c.Prima_total__c',
    'Tech_Seguro__c.Dias_para_vencer__c',
    'Tech_Fianza__c.Dias_para_vencer__c',
    'Tech_Recibo_Pago__c.Saldo__c'
)

# Todos los campos nuevos
$allFields = @(
    'Tech_Seguro__c.Ramo__c','Tech_Seguro__c.Subproducto__c','Tech_Seguro__c.Estatus__c',
    'Tech_Seguro__c.Inicio_del_seguro__c','Tech_Seguro__c.Fin_del_seguro__c',
    'Tech_Seguro__c.Frecuencia_de_pago__c','Tech_Seguro__c.Forma_de_pago__c',
    'Tech_Seguro__c.Prima_neta__c','Tech_Seguro__c.Descuento__c','Tech_Seguro__c.Recargos__c',
    'Tech_Seguro__c.Derechos__c','Tech_Seguro__c.IVA__c','Tech_Seguro__c.Ajuste__c',
    'Tech_Seguro__c.Prima_total__c','Tech_Seguro__c.Canal__c','Tech_Seguro__c.Tipo_originador__c',
    'Tech_Seguro__c.Dias_para_vencer__c','Tech_Seguro__c.Pct_Comision__c',
    'Tech_Seguro__c.Monto_Comision__c','Tech_Seguro__c.Semaforo_renovacion__c',
    'Tech_Fianza__c.Contrato__c','Tech_Fianza__c.Tipo_de_Riesgo__c',
    'Tech_Fianza__c.Fecha_de_Emision__c','Tech_Fianza__c.Fecha_de_Vencimiento__c',
    'Tech_Fianza__c.Monto_Afianzado__c','Tech_Fianza__c.Prima_neta__c',
    'Tech_Fianza__c.Monto_Afianzado_Vigente__c','Tech_Fianza__c.Prima_Vigente__c',
    'Tech_Fianza__c.Fecha_Vencimiento_Vigente__c','Tech_Fianza__c.Dias_para_vencer__c',
    'Tech_Fianza__c.Exposicion__c','Tech_Fianza__c.Vendedor__c',
    'Tech_Endoso__c.Fecha_efectiva__c','Tech_Endoso__c.Diferencia_monto__c',
    'Tech_Plan_de_Pago__c.Monto_total__c','Tech_Plan_de_Pago__c.Dia_cobro_mensual__c',
    'Tech_Plan_de_Pago__c.Domiciliacion_activa__c','Tech_Plan_de_Pago__c.Ultimos_4_digitos__c',
    'Tech_Plan_de_Pago__c.Referencia_domiciliacion__c',
    'Tech_Vendedor__c.Zona__c','Tech_Vendedor__c.Promotoria__c',
    'Tech_Vendedor__c.Porcentaje_Comision_Ollin__c','Tech_Vendedor__c.Fecha_Inicio__c',
    'Tech_Vendedor__c.Carga_Trabajo__c',
    'Tech_Recibo_Pago__c.Monto_cobrado__c','Tech_Recibo_Pago__c.Saldo__c',
    'Tech_Recibo_Pago__c.Referencia_pago__c',
    'Tech_Convenio_Modificatorio__c.Numero_Convenio__c',
    'Tech_Comision__c.Seguro__c','Tech_Comision__c.Fianza__c','Tech_Comision__c.Vendedor__c',
    'Tech_Comision__c.Pct_Aplicado__c','Tech_Comision__c.Monto_Ollin__c',
    'Tech_Comision__c.Monto_Vendedor__c','Tech_Comision__c.Estatus__c',
    'Tech_Comision__c.Tabla_Comision__c',
    'EjecutivoContacto__c.Institucion__c','EjecutivoContacto__c.Puesto__c',
    'EjecutivoContacto__c.Area__c','EjecutivoContacto__c.Es_Contacto_Principal__c',
    'EjecutivoContacto__c.Email__c','EjecutivoContacto__c.Telefono__c',
    'EjecutivoContacto__c.Celular__c',
    'Lead.Score__c','Lead.Puede_Reactivarse__c','Lead.Origen_Lead__c',
    'Lead.Motivo_No_Calificacion__c',
    'Opportunity.Ramo__c','Opportunity.Subproducto__c','Opportunity.Vendedor__c',
    'Opportunity.Tipo_Originador__c','Opportunity.Motivo_Cierre_Perdido__c',
    'Opportunity.Aseguradora_Competidora__c','Opportunity.Puede_Reactivarse__c',
    'Opportunity.Notas_Vendedor__c',
    'Contract.Vendedor__c','Contract.Contratista__c','Contract.Beneficiario__c',
    'Contract.Institucion__c','Contract.Valor_Contrato_Vigente__c',
    'Contract.Fin_Contrato_Vigente__c','Contract.Suma_Fianzas__c',
    'Contract.Exposicion_del__c'
)

$profilesPath = "force-app/main/default/profiles"
if (Test-Path $profilesPath) {
    $profileFiles = Get-ChildItem "$profilesPath/*.profile-meta.xml"
    foreach ($profileFile in $profileFiles) {
        $content = [System.IO.File]::ReadAllText($profileFile.FullName)
        $modified = $false
        $newEntries = ""

        foreach ($fieldRef in $allFields) {
            if ($content -notmatch "<field>$([regex]::Escape($fieldRef))</field>") {
                $isFormula = $formulaFields -contains $fieldRef
                $editable  = if ($isFormula) { 'false' } else { 'true' }
                $newEntries += @"

    <fieldPermissions>
        <editable>$editable</editable>
        <field>$fieldRef</field>
        <readable>true</readable>
    </fieldPermissions>
"@
                $modified = $true
            }
        }

        if ($modified) {
            $content = $content -replace '</Profile>', "$newEntries`n</Profile>"
            $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($content)
            [System.IO.File]::WriteAllBytes($profileFile.FullName, $bytes)
            Write-Host "  OK  $($profileFile.Name)" -ForegroundColor Green
            $script:CREATED++
        } else {
            Write-Host "  --  $($profileFile.Name) (ya tenía todos los permisos)" -ForegroundColor Yellow
            $script:SKIPPED++
        }
    }
} else {
    Write-Host "  !! No se encontró carpeta de perfiles. Ejecuta un retrieve primero." -ForegroundColor Red
}


# =============================================================================
# RESUMEN FINAL
# =============================================================================
Write-Host ""
Write-Host "==================================================" -ForegroundColor Blue
Write-Host "  RESUMEN FINAL" -ForegroundColor Blue
Write-Host "==================================================" -ForegroundColor Blue
Write-Host "  OK  Creados / actualizados : $script:CREATED" -ForegroundColor Green
Write-Host "  --  Ya existían / sin cambio: $script:SKIPPED" -ForegroundColor Yellow
Write-Host ""

# =============================================================================
# DEPLOY
# =============================================================================
if ($DEPLOY) {
    Write-Host "Iniciando deploy al org..." -ForegroundColor Cyan
    Write-Host ""
    sf project deploy start `
        --source-dir force-app/main/default/objects `
        --source-dir force-app/main/default/profiles `
        --ignore-conflicts `
        --wait 20
    Write-Host ""
    Write-Host "Deploy completado." -ForegroundColor Green
} else {
    Write-Host "Deploy omitido (--SoloArchivos)." -ForegroundColor Yellow
    Write-Host "   Para desplegar manualmente:"
    Write-Host "   sf project deploy start --source-dir force-app/main/default/objects --source-dir force-app/main/default/profiles" -ForegroundColor Cyan
}
