# Análisis de Arquitectura: Cliente vs. Implementación Actual
**Proyecto:** Ollin Protección — Salesforce  
**Fecha:** 2026-04-24  
**Branch:** implement-airtable-ProyectoOllin2026

---

## Tabla de contenidos

1. [Lo que tenemos correcto (o salvageable)](#1-lo-que-tenemos-correcto-o-salvageable)
2. [Lo que está estructuralmente mal](#2-lo-que-está-estructuralmente-mal)
3. [Lo que está completamente faltando](#3-lo-que-está-completamente-faltando)
4. [Resumen visual](#4-resumen-visual)
5. [¿Nuevo sandbox o modificar lo existente?](#5-nuevo-sandbox-o-modificar-lo-existente)
6. [Plan de acción](#6-plan-de-acción)

---

## 1. Lo que tenemos correcto (o salvageable)

| Concepto | Estado | Nota |
|---|---|---|
| `Fianza__c` | Existe, funcional | Tiene campos clave, estatus, fechas, montos |
| `Contrato__c` | Existe | Solo Name por ahora, pero el concepto es correcto |
| `Precalificacion__c` | Bien implementado | Campos financieros completos, Score ICP — NO está en el doc del cliente pero es parte del flujo real de Fianzas |
| `Proyecto__c` | Existe | El cliente lo menciona como campo en Contrato__c |
| `Vendedores__c` | Existe | Concepto correcto, naming incorrecto (ver sección 2) |
| Arquitectura Apex (Controller/Selector/Wrapper) | Sólida | Patrón reutilizable para toda la arquitectura nueva |
| LWC Airtable UI (20 componentes) | Funcional y valioso | El trabajo visual es rescatable |

---

## 2. Lo que está estructuralmente MAL

### 2.1 Relación Fianza → Contrato (crítico)

- **Lo que el cliente quiere:** `Fianza__c` es hijo **Master-Detail** de `Contrato__c` custom.
- **Lo que tenemos:** `No_Contrato__c` apunta al objeto **estándar** `Contract` (prefijo `800`). La relación a `Contrato__c` custom se hace mediante `Tech_Relacion__c` junction — esto es un parche, no la arquitectura correcta.

Con M-D nativo: si se elimina el Contrato se eliminan las Fianzas, los rollup fields funcionan sin código adicional, y la jerarquía queda explícita en Salesforce.

### 2.2 Contratista__c y Beneficiario__c como objetos custom separados

- **Lo que el cliente quiere:** Ambos son **Account** (estándar, Person Account para físicas).
- **Lo que tenemos:** Dos objetos custom `Contratista__c` y `Beneficiario__c` desconectados de Account, con un `Cliente__c` lookup a Account en Contratista. Esto duplica datos y no sigue el modelo Salesforce estándar.

> **Nota bloqueante:** `Contratista__c` tiene `Precalificacion__c` colgando de él — si se fusiona en Account, hay que decidir cómo migrar ese vínculo. Ver [decisión bloqueante](#decisión-bloqueante).

### 2.3 Tech_Relacion__c no está en la arquitectura del cliente

El objeto junction `Tech_Relacion__c` fue una solución de emergencia para relaciones M:N. En el modelo final del cliente las relaciones son directas (lookups y M-D). Sigue siendo útil en transición, pero no es la arquitectura objetivo.

### 2.4 Naming de Vendedor

| Tenemos | Cliente quiere |
|---|---|
| `Vendedores__c` (plural) | `Vendedor__c` (singular — convención estándar de Salesforce) |

### 2.5 Endoso__c con colisión de nombre

El `Endoso__c` actual se usa como "Ampliación" de Fianza. El cliente define dos objetos distintos:

- `Endoso__c` — hijo de `Seguro__c` (módulo Seguros)
- `Endoso_de_Fianza__c` — objeto propio, lookup a `Convenio_Modificatorio__c` (módulo Fianzas)

El `Endoso__c` actual colisiona con ambos y necesita ser separado.

---

## 3. Lo que está completamente faltando

### Módulo Seguros — 100% ausente

| Objeto | Descripción |
|---|---|
| `Seguro__c` | Objeto central unificado (reemplaza `Polizas__c` legacy) con ramos, vigencia, primas, path de estatus |
| `Endoso__c` (de Seguro) | Hijo M-D de Seguro, tipo de endoso, diferencia de prima |

### Módulo Fianzas — parcialmente ausente

| Objeto | Descripción |
|---|---|
| `Convenio_Modificatorio__c` | Hijo M-D de Contrato, amplía valor/plazo del contrato |
| `Endoso_de_Fianza__c` | Objeto propio, Lookup a Convenio, auto-actualiza campos Vigente__c de Fianza |

### Gestión / Cobranza — 100% ausente

| Objeto | Descripción |
|---|---|
| `Plan_de_Pagos__c` | Hijo M-D de Fianza (o Seguro), frecuencia y número de recibos |
| `Recibo__c` | Hijo M-D de Plan, estados: Programado → Por cobrar → Cobrado / Vencido / Parcial |

### Gestión / Comisiones — 100% ausente

| Objeto | Descripción |
|---|---|
| `Comision__c` | Hijo M-D de Fianza/Seguro, estados: Devengada → Liberada → Pagada |
| `Tabla_de_Comisiones__c` | Tabla maestra (Admin-only), Institución × Producto × Tipo, versionado histórico |

### Módulo Instituciones — 90% ausente

| Objeto | Descripción |
|---|---|
| `Institucion__c` | Catálogo de aseguradoras/afianzadoras (hoy solo existe como campo de texto en Fianza) |
| `EjecutivoContacto__c` | Hijo M-D de Institución, área, contacto principal |
| `AccesoPortal__c` | Hijo M-D de Institución, credenciales por tipo de portal (FLS restringido) |

### Flujo de Ventas — 100% ausente

| Componente | Descripción |
|---|---|
| Lead (estándar) | Con scoring 0–100, orígenes, reciclaje a 10–11 meses |
| Opportunity (estándar) | Estados de venta, cierre que genera Seguro o Contrato |
| Person Account | Objeto de Cliente (físico o moral) |
| Agentforce | IA nativa para captura 24/7 y cierres autónomos |

---

## 4. Resumen visual

```
MÓDULO                CLIENTE QUIERE              TENEMOS              DELTA
──────────────────────────────────────────────────────────────────────────────
Flujo de Ventas       Lead → Opp → Cliente        ✗ nada               -100%
Seguros               Seguro__c + hijos            ✗ nada               -100%
Fianzas — base        Contrato → Fianza (M-D)      ⚠ Parcial / mal       -60%
Fianzas — endosos     Convenio + EndosoFianza      ⚠ Endoso mal          -80%
Instituciones         Institución + hijos           ✗ solo campo texto    -90%
Cobranza              Plan + Recibo                 ✗ nada               -100%
Comisiones            Comisión + Tabla              ✗ nada               -100%
LWC UI Airtable       No especificado               ✅ funcional         +valor
Precalificación       No en doc, sí en negocio      ✅ completo          +valor
Arquitectura Apex     No especificado               ✅ patrón sólido     +valor
```

---

## 5. ¿Nuevo sandbox o modificar lo existente?

### Recomendación: Nuevo sandbox con migración selectiva de código

### Por qué NO basta con modificar el sandbox actual

**1. La relación Fianza → Contrato requiere borrar y recrear campos.**  
Cambiar de "Lookup a Contract estándar" a "M-D de Contrato__c custom" no es una modificación — es un campo completamente nuevo, migración de datos y eliminación del anterior. Destructivo en un org con datos reales.

**2. Contratista__c y Beneficiario__c como objetos custom vs Account**  
Es una decisión de modelo que afecta todas las relaciones, queries, LWCs y reportes. Revertirla en un org activo implica mover datos entre objetos, con riesgo de pérdida.

**3. Añadir 7+ módulos nuevos sobre una base incorrecta**  
Genera deuda técnica acumulada — construir el segundo piso sobre cimientos desviados.

**4. El Endoso__c tiene colisión de nombre**  
El mismo objeto sirve hoy para dos conceptos distintos (Endoso de Seguro y Ampliación de Fianza). Separarlo en un org activo requiere migración de registros existentes.

### Qué se rescata del org actual (sin re-implementar desde cero)

| Artefacto | Acción |
|---|---|
| Arquitectura Apex Controller/Selector/Wrapper | Migrar al nuevo modelo — ~20% refactor |
| 20 componentes LWC Airtable UI | Migrar — ~30% refactor por componente (solo cambia el Apex de fondo) |
| `Precalificacion__c` con todos sus campos | Copiar definición al nuevo sandbox |
| `Tech_Relacion__c` | Mantener en transición, deprecar gradualmente al tener M-D nativos |
| Seed scripts / datos de demo | Reescribir para nuevo modelo de datos |

---

## 6. Plan de acción

### Decisión bloqueante

> **Antes de empezar la Fase 1, confirmar con el cliente:**  
> ¿`Contratista__c` queda como objeto propio (con `Precalificacion__c` colgando) o se fusiona en Account?  
>
> - **Opción A — Objeto propio:** `Contratista__c` con Lookup a Account. `Fianza__c` → Lookup a `Contratista__c`. `Precalificacion__c` → M-D de `Contratista__c`. Modelo actual es cercano a esto.  
> - **Opción B — Account puro:** Todo sube a Account. `Precalificacion__c` → M-D de Account. Más alineado con el doc del cliente, más trabajo de migración.

---

### Fase 0 — Preparación (1 semana)

- [ ] Crear sandbox nuevo (Developer o Partial Copy de production)
- [ ] Exportar seed data de demo del org actual
- [ ] Documentar campos de `Precalificacion__c` que no están en el doc del cliente
- [ ] Confirmar decisión bloqueante sobre Contratista__c con el cliente
- [ ] Confirmar si `Proyecto__c` queda como objeto independiente o como campo en Contrato

---

### Fase 1 — Modelo de datos core de Fianzas (2 semanas)

Prioridad máxima: ya hay trabajo UI construido sobre esto.

- [ ] Crear `Institucion__c` con campos: Nombre (único), Tipo (Aseguradora/Afianzadora/Ambas), Estatus, rollups
- [ ] Crear `EjecutivoContacto__c` — hijo M-D de `Institucion__c`
- [ ] Crear `AccesoPortal__c` — hijo M-D de `Institucion__c` (FLS en contraseña)
- [ ] Redefinir `Contrato__c` con todos sus campos del doc del cliente (Valor, Beneficiario, Cliente, Institución, Vendedor, Proyecto, campos calculados Vigente__c)
- [ ] Crear `Fianza__c` como hijo **M-D de `Contrato__c`** — campo `Contrato__c` M-D
- [ ] Crear `Convenio_Modificatorio__c` — hijo M-D de `Contrato__c`
- [ ] Crear `Endoso_de_Fianza__c` — con Lookup a `Convenio_Modificatorio__c`, auto-actualiza `Fianza__c` campos Vigente__c
- [ ] Renombrar/reusar `Endoso__c` — reservar para módulo Seguros (Fase 3)
- [ ] Renombrar `Vendedores__c` → `Vendedor__c`
- [ ] Migrar Apex: actualizar todos los Selectors y Wrappers al nuevo modelo de relaciones
- [ ] Migrar LWC: actualizar `techFianzas`, `techContratistas`, `techContratos`, `techContratistaInterfaces` al nuevo Apex
- [ ] Actualizar `Tech_Relacion__c`: agregar/quitar Lookups según nuevas relaciones

---

### Fase 2 — Cobranza y Comisiones (2 semanas)

- [ ] Crear `Plan_de_Pagos__c` — M-D de `Fianza__c` (luego reutilizar para `Seguro__c`)
- [ ] Crear `Recibo__c` — M-D de `Plan_de_Pagos__c`
- [ ] Crear `Tabla_de_Comisiones__c` — maestra, acceso exclusivo de Admin, versionado histórico
- [ ] Crear `Comision__c` — M-D de `Fianza__c`
- [ ] Automatización: liberar comisión al marcar Recibo como Cobrado
- [ ] Automatización: clawback proporcional al cancelar Fianza
- [ ] Automatización: ajuste de recibos futuros si Endoso afecta prima
- [ ] LWC: panel de cobranza y comisiones por Fianza

---

### Fase 3 — Módulo Seguros (2 semanas)

- [ ] Crear `Seguro__c` con todos sus campos (ramos, vigencia, primas, detalle IVA, tipo originador, canal, promotoría, "Póliza renovada de" self-lookup)
- [ ] Crear `Endoso__c` de Seguro — M-D de `Seguro__c`
- [ ] Reutilizar `Plan_de_Pagos__c` y `Recibo__c` de Fase 2 para Seguros
- [ ] Automatización: cálculo diario de Días para vencer
- [ ] Automatización: cambio de estatus a "Por renovar" según ramo (Auto 45d, GMM 60d, Vida/PPR 90d, Daños 30d)
- [ ] Automatización: cálculo de % Comisión desde `Tabla_de_Comisiones__c`
- [ ] Automatización: cálculo Prima total = Subtotal + IVA + Ajuste
- [ ] LWC: `techSeguros` tab en el Airtable UI

---

### Fase 4 — Flujo de Ventas (2 semanas)

- [ ] Configurar Lead estándar: campos mínimos por producto, scoring 0–100 (60+25+15)
- [ ] Proceso de conversión Lead → Oportunidad (solo desde Lead Calificado)
- [ ] Configurar Opportunity: estados de venta, campos de cierre perdido (motivo, puede reactivarse)
- [ ] Automatización cierre Ganado: crear Seguro o Contrato, heredar Cliente/Vendedor/Institución
- [ ] Automatización reciclaje: crear Lead "Reciclado" a 10–11 meses de cierre perdido reactivable
- [ ] Configurar `Vendedor__c` con asignación desde Oportunidad
- [ ] Person Account habilitado para clientes personas físicas
- [ ] LWC: `techProspeccion` (ya existe, validar y conectar)

---

### Fase 5 — Gestión avanzada y reportes (ongoing)

- [ ] Capa de Renovaciones: alertas automáticas por ramo, crear Oportunidad de renovación, vínculo "Póliza renovada de"
- [ ] Capa de Remarketing: cadencias post-cierre perdido (7d, 30d, 60d, 90d), cross-sell por producto único
- [ ] Digital Engagement: configurar WhatsApp, SMS, Messenger (reemplaza Respond.io)
- [ ] 5 tableros de reportes: Ventas, Marketing, Operaciones, Promotoría, Agentforce IA
- [ ] Sub-módulo Admin Tabla de Comisiones: edición inline + carga CSV + log de auditoría

---

### Fase 6 — Migración LWC Airtable UI (paralelo a Fases 1–3)

Los 20 componentes son rescatables. La capa de presentación (HTML/CSS/JS) se reutiliza casi en su totalidad; lo que cambia es el Apex de fondo.

| Componente | Esfuerzo estimado | Acción |
|---|---|---|
| `techFianzas` | Medio | Actualizar Selector/Wrapper al nuevo M-D |
| `techContratistas` | Medio | Actualizar si Contratista queda como objeto propio |
| `techContratos` | Bajo | Agregar campos del nuevo Contrato__c |
| `techContratistaInterfaces` | Bajo | Ajustar dashboard al nuevo modelo |
| `techAmpliaciones` | Alto | Separar en EndosoFianza + EndosoSeguro |
| `techBeneficiarios` | Medio | Resolver si es Account o custom |
| `techAfianzados` | Medio | Alinear con Person Account |
| `techProyectos` | Bajo | Verificar relación con Contrato |
| `techPrecalificacionPanel` | Bajo | Solo verificar lookup a Contratista/Account |
| Nuevos: Seguros, Cobranza, Comisiones | Alto | Implementar desde cero |

---

## Notas finales

- El **patrón arquitectónico** (Controller/Selector/Wrapper + LWC Airtable) es el activo más valioso del org actual. No se descarta nada, se migra.
- El **sandbox actual** puede funcionar como ambiente de referencia durante la migración.
- La **`Precalificacion__c`** es un objeto completo y valioso que el cliente probablemente quiere aunque no esté en el documento de arquitectura de datos — confirmar con ellos antes de mover.
- **SPIFF** (comisiones): decisión pendiente del cliente — integrar, migrar o solo enlazar. Impacta el diseño de `Comision__c` y `Tabla_de_Comisiones__c`.
