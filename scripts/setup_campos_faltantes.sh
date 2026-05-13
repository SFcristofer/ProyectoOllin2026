#!/bin/bash
# =============================================================================
# ProyectoOllin2026 — Creación de campos y objetos faltantes
# Genera todos los archivos .field-meta.xml y .object-meta.xml requeridos
# para cubrir el documento de estructura de datos del cliente.
#
# Uso:
#   bash scripts/setup_campos_faltantes.sh                  → crea archivos + despliega
#   bash scripts/setup_campos_faltantes.sh --solo-archivos  → solo crea archivos, sin deploy
# =============================================================================

set -euo pipefail

OBJECTS_PATH="force-app/main/default/objects"
DEPLOY=true
[[ "${1:-}" == "--solo-archivos" ]] && DEPLOY=false

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'
CREATED=0; SKIPPED=0

ok()      { echo -e "  ${GREEN}✅${NC} $1"; ((CREATED++)); }
skip()    { echo -e "  ${YELLOW}⏭ ${NC} $1 (ya existe)"; ((SKIPPED++)); }
section() { echo -e "\n${BLUE}══════════════════════════════════════════════════${NC}"; echo -e "${BLUE}  $1${NC}"; echo -e "${BLUE}══════════════════════════════════════════════════${NC}"; }

# -----------------------------------------------------------------------------
# Crea un campo si no existe. Recibe: objeto, nombre_campo, luego el XML por stdin
# -----------------------------------------------------------------------------
write_field() {
    local obj=$1 name=$2
    local dir="$OBJECTS_PATH/$obj/fields"
    mkdir -p "$dir"
    local file="$dir/$name.field-meta.xml"
    if [[ ! -f "$file" ]]; then
        cat > "$file"
        ok "$obj  ›  $name"
    else
        skip "$obj  ›  $name"
        cat > /dev/null
    fi
}

# Crea object-meta.xml si no existe
write_object() {
    local name=$1
    local dir="$OBJECTS_PATH/$name"
    mkdir -p "$dir"
    local file="$dir/$name.object-meta.xml"
    if [[ ! -f "$file" ]]; then
        cat > "$file"
        ok "Objeto creado: $name"
    else
        skip "Objeto: $name"
        cat > /dev/null
    fi
}


# =============================================================================
# 1 · Tech_Seguro__c — campos faltantes
# =============================================================================
section "1 · Tech_Seguro__c  (le faltan ~18 campos)"

write_field "Tech_Seguro__c" "Ramo__c" << 'EOF'
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
EOF

write_field "Tech_Seguro__c" "Subproducto__c" << 'EOF'
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
EOF

write_field "Tech_Seguro__c" "Estatus__c" << 'EOF'
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
EOF

write_field "Tech_Seguro__c" "Inicio_del_seguro__c" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Inicio_del_seguro__c</fullName>
    <label>Inicio del seguro</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Date</type>
</CustomField>
EOF

write_field "Tech_Seguro__c" "Fin_del_seguro__c" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Fin_del_seguro__c</fullName>
    <label>Fin del seguro</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Date</type>
</CustomField>
EOF

write_field "Tech_Seguro__c" "Frecuencia_de_pago__c" << 'EOF'
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
EOF

write_field "Tech_Seguro__c" "Forma_de_pago__c" << 'EOF'
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
EOF

write_field "Tech_Seguro__c" "Prima_neta__c" << 'EOF'
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
EOF

write_field "Tech_Seguro__c" "Descuento__c" << 'EOF'
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
EOF

write_field "Tech_Seguro__c" "Recargos__c" << 'EOF'
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
EOF

write_field "Tech_Seguro__c" "Derechos__c" << 'EOF'
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
EOF

write_field "Tech_Seguro__c" "IVA__c" << 'EOF'
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
EOF

write_field "Tech_Seguro__c" "Ajuste__c" << 'EOF'
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
EOF

write_field "Tech_Seguro__c" "Prima_total__c" << 'EOF'
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
EOF

write_field "Tech_Seguro__c" "Canal__c" << 'EOF'
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
EOF

write_field "Tech_Seguro__c" "Tipo_originador__c" << 'EOF'
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
EOF

write_field "Tech_Seguro__c" "Dias_para_vencer__c" << 'EOF'
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
EOF

write_field "Tech_Seguro__c" "Pct_Comision__c" << 'EOF'
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
EOF

write_field "Tech_Seguro__c" "Monto_Comision__c" << 'EOF'
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
EOF

write_field "Tech_Seguro__c" "Semaforo_renovacion__c" << 'EOF'
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
EOF


# =============================================================================
# 2 · Tech_Fianza__c — campos faltantes
# =============================================================================
section "2 · Tech_Fianza__c  (le faltan ~12 campos)"

write_field "Tech_Fianza__c" "Contrato__c" << 'EOF'
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
EOF

write_field "Tech_Fianza__c" "Tipo_de_Riesgo__c" << 'EOF'
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
EOF

write_field "Tech_Fianza__c" "Fecha_de_Emision__c" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Fecha_de_Emision__c</fullName>
    <label>Fecha de emisión</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Date</type>
</CustomField>
EOF

write_field "Tech_Fianza__c" "Fecha_de_Vencimiento__c" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Fecha_de_Vencimiento__c</fullName>
    <label>Fecha de vencimiento (original)</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Date</type>
</CustomField>
EOF

write_field "Tech_Fianza__c" "Monto_Afianzado__c" << 'EOF'
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
EOF

write_field "Tech_Fianza__c" "Prima_neta__c" << 'EOF'
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
EOF

write_field "Tech_Fianza__c" "Monto_Afianzado_Vigente__c" << 'EOF'
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
EOF

write_field "Tech_Fianza__c" "Prima_Vigente__c" << 'EOF'
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
EOF

write_field "Tech_Fianza__c" "Fecha_Vencimiento_Vigente__c" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Fecha_Vencimiento_Vigente__c</fullName>
    <label>Fecha vencimiento vigente</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Date</type>
</CustomField>
EOF

write_field "Tech_Fianza__c" "Dias_para_vencer__c" << 'EOF'
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
EOF

write_field "Tech_Fianza__c" "Exposicion__c" << 'EOF'
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
EOF

write_field "Tech_Fianza__c" "Vendedor__c" << 'EOF'
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
EOF


# =============================================================================
# 3 · Tech_Endoso__c — campos faltantes (dual: Seguro y Fianza)
# =============================================================================
section "3 · Tech_Endoso__c  (faltan 2 campos — objeto dual Seguro + Fianza)"

write_field "Tech_Endoso__c" "Fecha_efectiva__c" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Fecha_efectiva__c</fullName>
    <label>Fecha efectiva</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Date</type>
</CustomField>
EOF

write_field "Tech_Endoso__c" "Diferencia_monto__c" << 'EOF'
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
EOF


# =============================================================================
# 4 · Tech_Plan_de_Pago__c — campos de domiciliación faltantes
# =============================================================================
section "4 · Tech_Plan_de_Pago__c  (faltan 5 campos — domiciliación)"

write_field "Tech_Plan_de_Pago__c" "Monto_total__c" << 'EOF'
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
EOF

write_field "Tech_Plan_de_Pago__c" "Dia_cobro_mensual__c" << 'EOF'
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
EOF

write_field "Tech_Plan_de_Pago__c" "Domiciliacion_activa__c" << 'EOF'
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
EOF

write_field "Tech_Plan_de_Pago__c" "Ultimos_4_digitos__c" << 'EOF'
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
EOF

write_field "Tech_Plan_de_Pago__c" "Referencia_domiciliacion__c" << 'EOF'
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
EOF


# =============================================================================
# 5 · Tech_Vendedor__c — campos de perfil comercial faltantes
# =============================================================================
section "5 · Tech_Vendedor__c  (faltan 5 campos)"

write_field "Tech_Vendedor__c" "Zona__c" << 'EOF'
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
EOF

write_field "Tech_Vendedor__c" "Promotoria__c" << 'EOF'
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
EOF

write_field "Tech_Vendedor__c" "Porcentaje_Comision_Ollin__c" << 'EOF'
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
EOF

write_field "Tech_Vendedor__c" "Fecha_Inicio__c" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Fecha_Inicio__c</fullName>
    <label>Fecha de inicio</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Date</type>
</CustomField>
EOF

write_field "Tech_Vendedor__c" "Carga_Trabajo__c" << 'EOF'
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
EOF


# =============================================================================
# 6 · Tech_Recibo_Pago__c — campos de pago parcial faltantes
# =============================================================================
section "6 · Tech_Recibo_Pago__c  (faltan 3 campos)"

write_field "Tech_Recibo_Pago__c" "Monto_cobrado__c" << 'EOF'
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
EOF

write_field "Tech_Recibo_Pago__c" "Saldo__c" << 'EOF'
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
EOF

write_field "Tech_Recibo_Pago__c" "Referencia_pago__c" << 'EOF'
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
EOF


# =============================================================================
# 7 · Tech_Convenio_Modificatorio__c — número autonumérico
# =============================================================================
section "7 · Tech_Convenio_Modificatorio__c  (falta 1 campo)"

write_field "Tech_Convenio_Modificatorio__c" "Numero_Convenio__c" << 'EOF'
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
EOF


# =============================================================================
# 8 · NUEVO OBJETO: Tech_Comision__c
# =============================================================================
section "8 · NUEVO OBJETO: Tech_Comision__c  (capa de comisiones)"

write_object "Tech_Comision__c" << 'EOF'
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
EOF

write_field "Tech_Comision__c" "Seguro__c" << 'EOF'
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
EOF

write_field "Tech_Comision__c" "Fianza__c" << 'EOF'
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
EOF

write_field "Tech_Comision__c" "Vendedor__c" << 'EOF'
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
EOF

write_field "Tech_Comision__c" "Pct_Aplicado__c" << 'EOF'
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
EOF

write_field "Tech_Comision__c" "Monto_Ollin__c" << 'EOF'
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
EOF

write_field "Tech_Comision__c" "Monto_Vendedor__c" << 'EOF'
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
EOF

write_field "Tech_Comision__c" "Estatus__c" << 'EOF'
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
EOF

write_field "Tech_Comision__c" "Tabla_Comision__c" << 'EOF'
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
EOF


# =============================================================================
# 9 · NUEVO OBJETO: EjecutivoContacto__c
# =============================================================================
section "9 · NUEVO OBJETO: EjecutivoContacto__c  (hijo M-D de Institucion__c)"

write_object "EjecutivoContacto__c" << 'EOF'
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
EOF

write_field "EjecutivoContacto__c" "Institucion__c" << 'EOF'
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
EOF

write_field "EjecutivoContacto__c" "Puesto__c" << 'EOF'
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
EOF

write_field "EjecutivoContacto__c" "Area__c" << 'EOF'
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
EOF

write_field "EjecutivoContacto__c" "Es_Contacto_Principal__c" << 'EOF'
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
EOF

write_field "EjecutivoContacto__c" "Email__c" << 'EOF'
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
EOF

write_field "EjecutivoContacto__c" "Telefono__c" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Telefono__c</fullName>
    <label>Teléfono directo</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Phone</type>
</CustomField>
EOF

write_field "EjecutivoContacto__c" "Celular__c" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Celular__c</fullName>
    <label>Celular</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Phone</type>
</CustomField>
EOF


# =============================================================================
# 10 · Lead (estándar) — campos custom para Flujo de Ventas
# =============================================================================
section "10 · Lead  (objeto estándar — campos custom del Flujo de Ventas)"

write_field "Lead" "Score__c" << 'EOF'
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
EOF

write_field "Lead" "Puede_Reactivarse__c" << 'EOF'
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
EOF

write_field "Lead" "Origen_Lead__c" << 'EOF'
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
EOF

write_field "Lead" "Motivo_No_Calificacion__c" << 'EOF'
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
EOF


# =============================================================================
# 11 · Opportunity (estándar) — campos custom para Flujo de Ventas
# =============================================================================
section "11 · Opportunity  (objeto estándar — campos custom del Flujo de Ventas)"

write_field "Opportunity" "Ramo__c" << 'EOF'
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
EOF

write_field "Opportunity" "Subproducto__c" << 'EOF'
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
EOF

write_field "Opportunity" "Vendedor__c" << 'EOF'
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
EOF

write_field "Opportunity" "Tipo_Originador__c" << 'EOF'
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
EOF

write_field "Opportunity" "Motivo_Cierre_Perdido__c" << 'EOF'
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
EOF

write_field "Opportunity" "Aseguradora_Competidora__c" << 'EOF'
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
EOF

write_field "Opportunity" "Puede_Reactivarse__c" << 'EOF'
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
EOF

write_field "Opportunity" "Notas_Vendedor__c" << 'EOF'
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
EOF


# =============================================================================
# 12 · Contract (estándar) — campos custom para módulo Fianzas
# =============================================================================
section "12 · Contract  (objeto estándar — padre de Tech_Fianza__c y Convenio)"

write_field "Contract" "Vendedor__c" << 'EOF'
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
EOF

write_field "Contract" "Contratista__c" << 'EOF'
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
EOF

write_field "Contract" "Beneficiario__c" << 'EOF'
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
EOF

write_field "Contract" "Institucion__c" << 'EOF'
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
EOF

write_field "Contract" "Valor_Contrato_Vigente__c" << 'EOF'
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
EOF

write_field "Contract" "Fin_Contrato_Vigente__c" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Fin_Contrato_Vigente__c</fullName>
    <label>Fin contrato vigente</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Date</type>
</CustomField>
EOF

write_field "Contract" "Suma_Fianzas__c" << 'EOF'
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
EOF

write_field "Contract" "Exposicion_del__c" << 'EOF'
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
EOF


# =============================================================================
# RESUMEN
# =============================================================================
echo ""
echo -e "${BLUE}══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  RESUMEN${NC}"
echo -e "${BLUE}══════════════════════════════════════════════════${NC}"
echo -e "  ${GREEN}✅ Creados  : $CREATED${NC}"
echo -e "  ${YELLOW}⏭  Existían : $SKIPPED${NC}"
echo ""

# =============================================================================
# DEPLOY
# =============================================================================
if [[ "$DEPLOY" == "true" ]]; then
    echo -e "${CYAN}🚀 Iniciando deploy al org...${NC}"
    echo ""
    sf project deploy start \
        --source-dir force-app/main/default/objects \
        --ignore-conflicts \
        --wait 20
    echo ""
    echo -e "${GREEN}✅ Deploy completado.${NC}"
else
    echo -e "${YELLOW}⏭  Deploy omitido (--solo-archivos).${NC}"
    echo -e "   Para desplegar manualmente:"
    echo -e "   ${CYAN}sf project deploy start --source-dir force-app/main/default/objects${NC}"
fi
