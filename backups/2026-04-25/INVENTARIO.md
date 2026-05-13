# Inventario del Org — Ollin Protección
**Fecha:** 2026-04-25  
**Org:** soporte.technovalue@ollin.com.mx.dev  
**Generado por:** Módulo 0 — Plan de Trabajo Admin

---

## CSVs exportados (datos)

| Archivo | Objeto |
|---------|--------|
| Fianza__c.csv | Fianzas |
| Contrato__c.csv | Contratos |
| Contratista__c.csv | Contratistas |
| Beneficiario__c.csv | Beneficiarios |
| Endoso__c.csv | Endosos (mezcla Convenio + Endoso) |
| Vendedores__c.csv | Vendedores/Agentes |
| Tech_Relacion__c.csv | Junction Tech_Relacion__c |
| Proyecto__c.csv | Proyectos |
| Precalificacion__c.csv | Precalificaciones |

---

## Page Layouts recuperados (force-app/main/default/layouts/)

- Beneficiario__c — Formato Beneficiario
- Contratista__c — Formato Contratista
- Contrato__c — Formato Contrato
- Endoso__c — Formato Endoso
- Fianza__c — Formato Fianza
- Precalificacion__c — Formato Precalificación
- Proyecto__c — Formato Proyecto
- Tech_Relacion__c — Formato Relación Técnica
- Vendedores__c — Formato Vendedor

---

## Perfiles recuperados (force-app/main/default/profiles/)

Standard, Admin, Read Only, formulario registro Perfil, y los perfiles estándar de Salesforce.

---

## Flows ACTIVOS del proyecto (ActiveVersionId poblado, ApiName sin namespace)

Estos flows son propios del org (no son de paquetes de Salesforce):

| ApiName | Label | Tipo |
|---------|-------|------|
| Auto_Update_Contrato_After_Convenio | Auto Update Contrato After Convenio | AutoLaunchedFlow |
| Auto_Update_Fianza_After_Endoso | Auto Update Fianza After Endoso | AutoLaunchedFlow |
| Before_Save_Contrato_Init | Before Save Contrato Init | AutoLaunchedFlow |
| Before_Save_Fianza_Init | Before Save Fianza Init | AutoLaunchedFlow |
| Recordatorios_Recibos_Cobro | Recordatorios Recibos de Cobro | AutoLaunchedFlow |
| Route_to_Ollin | Route to Ollin | RoutingFlow |
| Tech_Agentforce_Registro_de_Leads_Seguros | Tech Agentforce - Registro de Leads Seguros | AutoLaunchedFlow |
| TECH_Asignar_Leads | TECH Asignar Leads | AutoLaunchedFlow |
| Wizard_Contrato_Fianzas | Wizard Contrato y Fianzas | Flow |
| Wizard_Convenio_Endoso | Wizard Convenio Modificatorio y Endoso | Flow |

## Flows en BORRADOR (sin ActiveVersionId, propios del org)

| ApiName | Label |
|---------|-------|
| Asignacion_Oportunidad_4_Niveles | Asignacion Oportunidad 4 Niveles |
| Handoff_AI_A_Humano | Handoff AI a Humano |

---

## ⚠️ Nota sobre Flows activos

Los flows **Auto_Update_Contrato_After_Convenio**, **Auto_Update_Fianza_After_Endoso**, **Before_Save_Contrato_Init** y **Before_Save_Fianza_Init** son trigger-based y tocan directamente los objetos que se van a modificar. Desactivarlos antes del Módulo 3 (reestructura de Fianza__c).

Los flows **Wizard_Contrato_Fianzas** y **Wizard_Convenio_Endoso** son flows de pantalla (Screen Flows). Revisarlos antes de modificar los objetos relacionados.
