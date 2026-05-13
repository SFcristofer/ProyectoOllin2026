# Handoff: Módulo Pólizas — Ollin Protección (LWC / Salesforce)

## Overview

Este handoff documenta el diseño de la nueva pestaña **"Pólizas"** dentro del módulo LWC existente de Ollin Protección. El módulo actualmente tiene las pestañas Dashboard, Prospectos, Oportunidades y Clientes. Se agrega una quinta pestaña que da visibilidad completa del flujo post-venta:

```
Prospecto → Oportunidad → [Cierre Ganado] → Seguro / Fianza → Plan de Pagos → Recibos de Cobro
                                                              ↳ Endosos
                                                              ↳ Renovación
                                                              ↳ Comisiones
```

## Sobre los archivos de diseño

Los archivos `.html` y `.jsx` en este paquete son **prototipos de referencia de diseño** creados con React/Babel. **NO son código de producción** — son referencias visuales e interactivas que muestran la intención de diseño, comportamiento y flujo.

La tarea del desarrollador es **recrear estos diseños en LWC (Lightning Web Components)** dentro del org de Salesforce de Ollin, usando:
- Componentes nativos de SLDS donde aplique (`lightning-datatable`, `lightning-tabset`, `lightning-badge`, etc.)
- `@wire` + LDS para lectura de datos
- Apex imperativo para operaciones de escritura
- NavigationMixin para navegación y acciones

## Fidelidad

**Alta fidelidad (hifi):** Los prototipos son pixel-perfect en cuanto a colores, tipografía, espaciado e interacciones. El desarrollador debe recrear la UI con la mayor fidelidad posible usando el sistema de diseño de Salesforce (SLDS) como base, aplicando los tokens de color de Ollin encima.

---

## Pantallas / Vistas

### 1. Pestaña "Pólizas" — Vista principal

**Propósito:** Dar visibilidad completa de todas las pólizas (Seguros y Fianzas) del vendedor, con acceso a Plan de Pagos, Recibos, Endosos y acciones de Renovación desde una sola pantalla.

**Layout:**
- Contenedor full-width dentro del LWC existente
- Header con tabs de navegación del módulo (reutilizar componente existente)
- Toolbar con sub-tabs, buscador y filtro de estatus
- Banner desplegable de información técnica (puede omitirse en producción)
- Tabla principal con árbol expandible
- Panel lateral deslizante de detalle (ancho: 360px, posición: `position: absolute; right: 0`)

**Sub-tabs (dentro de Pólizas):**
- `Seguros` — filtra objetos `Seguro__c`
- `Fianzas / PPR` — filtra objetos `Fianza__c` y PPR

---

### 2. Tabla con árbol expandible (componente principal)

**Columnas:**

| Columna | Campo Salesforce | Notas |
|---|---|---|
| Póliza / Plan / Recibo | `Name` o `Numero_Poliza__c` | Link clickeable, con badge de Ramo y badge de Renovación si vence ≤90 días |
| Cliente | `Cliente__c` (Lookup a Account) | Texto, no link en tabla |
| Aseguradora | `Aseguradora__c` | Texto |
| Estatus | `Estatus__c` | Badge con color semántico |
| Recibos pagados | Calculado | Barra de progreso: recibos con estatus "Pagado" / total recibos del Plan |
| % Comisión | `Comision__c` | Número en verde si > 0, guión si vacío |
| Endosos | COUNT de `Endoso_de_Seguro__c` | Contador con badge morado, expandible |

**Jerarquía del árbol (3 niveles):**
```
Nivel 0: Seguro__c / Fianza__c  (ícono escudo)
  Nivel 1a: Endoso_de_Seguro__c[]  (ícono triángulo, solo si hay endosos)
  Nivel 1b: Plan_de_Pagos__c  (ícono documento)
    Nivel 2: Recibo_de_Cobro__c[]  (ícono recibo)
```

**Comportamiento expand/collapse:**
- Click en fila de póliza → expande/colapsa sus hijos Y abre panel lateral de detalle
- Click en fila de Plan → expande/colapsa recibos Y abre panel lateral de Plan
- Click en fila de Recibo → abre panel lateral de Recibo
- Click en sección Endosos → expande/colapsa lista de endosos
- Estado de expansión persistente durante la sesión (no necesita localStorage)

---

### 3. Panel lateral de detalle (slide-in)

**Comportamiento:**
- Se abre al seleccionar cualquier fila
- Ancho fijo: 360px
- Posición: `absolute; top:0; right:0; bottom:0`
- La tabla se contrae con `padding-right: 360px` cuando el panel está abierto
- Botón X para cerrar

**Tabs dentro del panel (solo para pólizas):**

#### Tab "Detalles"
Campos a mostrar para Seguro__c:
- Número de póliza
- Cliente (link)
- Aseguradora
- Ramo
- Producto
- Vendedor
- Prima neta (formateado como moneda)
- % Comisión
- Comisión estimada (prima × % comisión, calculado en JS)
- Inicio de vigencia
- Fin de vigencia
- Estatus

#### Tab "Endosos (N)"
- Lista de tarjetas por cada `Endoso_de_Seguro__c`
- Cada tarjeta muestra: folio, tipo, fecha efectiva, diferencia de monto, estatus
- Botón "+ Crear endoso" al final → NavigationMixin a página de creación con defaults

#### Tab "Plan de Pago"
- Resumen del `Plan_de_Pagos__c` relacionado
- Barra de progreso de recibos pagados

**Para Recibos:**
- Campos: Folio, Monto, Fecha Vencimiento, Estatus
- Botón "Marcar como Pagado" → `updateRecord()` que cambia `Estatus__c` a "Pagado"

**Para Endosos (cuando se selecciona directo):**
- Campos: Folio, Tipo, Fecha efectiva, Diferencia monto, Estatus

---

### 4. Badge de Renovación

**Lógica:**
```
diasParaVencer = vigenciaFin - TODAY()
si diasParaVencer ≤ 60  → badge ROJO    "⟳ Vence en Xd"
si diasParaVencer ≤ 90  → badge ÁMBAR   "⟳ Vence en Xd"
si diasParaVencer > 90  → no mostrar badge
```

**Implementación recomendada:**
- Campo fórmula en `Seguro__c`: `Dias_Para_Vencer__c = Fin_Seguro__c - TODAY()`
- En LWC: renderizar badge condicionalmente con `if:true={isUrgent}`

**Al hacer click en el badge:**
- Abrir modal de confirmación
- Al confirmar: `NavigationMixin.Navigate` para crear nueva `Opportunity` con:
  - `Poliza_Renovada__c` = ID de la póliza actual
  - `StageName` = "Prospección"
  - `AccountId` = cliente de la póliza

---

### 5. Modal de Renovación

**Contenido:**
- Título: "Iniciar renovación"
- Descripción: Explica que se creará una Oportunidad vinculada
- Resumen: nombre de póliza, días para vencer, fecha fin
- Botones: "Cancelar" (secundario) | "Crear oportunidad de renovación" (primario)

---

## Interacciones y Comportamiento

### Búsqueda
- Input de texto en toolbar
- Filtra en tiempo real por `Name` y `Cliente__c`
- Mínimo 1 carácter para activar filtro

### Filtro de estatus
- Select con opciones: Todos / Emitida / Cancelada
- Aplica sobre la lista de pólizas del sub-tab activo

### Marcar recibo como pagado
```javascript
// LWC — Apex imperativo o LDS updateRecord
import { updateRecord } from 'lightning/uiRecordApi';
import ESTATUS_FIELD from '@salesforce/schema/Recibo_de_Cobro__c.Estatus__c';

updateRecord({
  fields: {
    Id: reciboId,
    [ESTATUS_FIELD.fieldApiName]: 'Pagado'
  }
});
```
- Al pagarse un recibo → recalcular barra de progreso del plan
- Toast de confirmación: "Recibo marcado como pagado"

### Crear endoso
```javascript
NavigationMixin.Navigate({
  type: 'standard__objectPage',
  attributes: { objectApiName: 'Endoso_de_Seguro__c', actionName: 'new' },
  state: { defaultFieldValues: `Seguro__c=${polizaId}` }
});
```

---

## Gestión de Estado

| Variable | Tipo | Descripción |
|---|---|---|
| `activeSubTab` | string | `'seguros'` o `'fianzas'` |
| `searchTerm` | string | Texto de búsqueda |
| `filterEstatus` | string | Estatus seleccionado en filtro |
| `expandedRows` | Set\<string\> | IDs de filas expandidas |
| `selectedItemId` | string | ID del elemento seleccionado en panel lateral |
| `selectedItemType` | string | `'poliza'`, `'plan'`, `'recibo'`, `'endoso'` |
| `panelActiveTab` | string | Tab activa en panel lateral |

---

## Consultas de datos (SOQL sugerido)

### Carga inicial de Seguros con hijos
```sql
SELECT Id, Name, Cliente__c, Cliente__r.Name, Aseguradora__c, Ramo__c,
       Producto__c, Vendedor__c, Prima_Neta__c, Comision__c,
       Inicio_Seguro__c, Fin_Seguro__c, Estatus__c,
       Dias_Para_Vencer__c,
       (SELECT Id, Name, Tipo__c, Fecha_Efectiva__c,
               Diferencia_Monto__c, Estatus__c
        FROM Endosos_de_Seguro__r),
       (SELECT Id, Name, Frecuencia_Pago__c, Metodo_Pago__c,
               Fecha_Inicio__c, Num_Recibos__c, Estatus__c,
               (SELECT Id, Name, Monto__c, Fecha_Vencimiento__c, Estatus__c
                FROM Recibos_de_Cobro__r)
        FROM Planes_de_Pago__r)
FROM Seguro__c
WHERE OwnerId = :currentUserId
ORDER BY CreatedDate DESC
LIMIT 200
```

---

## Design Tokens — Paleta Ollin

```css
/* Colores de marca */
--color-charcoal:        #2a2a2a;   /* Headers, botones primarios, texto fuerte */
--color-charcoal-hover:  #404040;   /* Hover de botones primarios */
--color-blue:            #1a56db;   /* Links, tabs activas, focus rings */
--color-blue-hover:      #1549c0;   /* Hover sobre elementos azules */
--color-tab-inactive:    #4b5563;   /* Texto de pestañas inactivas */

/* Colores semánticos (estado) */
--color-green-bg:        #d1fae5;
--color-green-text:      #065f46;   /* Pagado, OK, Comisión */
--color-red-bg:          #fee2e2;
--color-red-text:        #991b1b;   /* Vencido, error */
--color-amber-bg:        #fef3c7;
--color-amber-text:      #92400e;   /* Pendiente, advertencia */
--color-blue-light-bg:   #dbeafe;
--color-blue-light-text: #1a56db;   /* Informativo, Emitida */

/* Ramos */
--color-auto-bg:         #ede9fe;
--color-auto-text:       #5b21b6;   /* Auto */
--color-ppr-bg:          #fce7f3;
--color-ppr-text:        #9d174d;   /* PPR */
--color-fianza-bg:       #e0f2fe;
--color-fianza-text:     #0369a1;   /* Fianza */
--color-endoso-bg:       #ede9fe;
--color-endoso-text:     #5b21b6;   /* Contador endosos */

/* Superficies */
--color-border:          #e5e7eb;
--color-surface:         #f9fafb;
--color-white:           #ffffff;
```

---

## Tipografía

| Uso | Font | Size | Weight |
|---|---|---|---|
| Nombre de póliza en tabla | Inter | 12px | 600 |
| Datos en tabla | Inter | 12px | 400 |
| Headers de columna | Inter | 11px | 700 (uppercase) |
| Texto en panel lateral | Inter | 12px | 400 |
| Título en panel lateral | Inter | 14px | 700 |
| Badges | Inter | 11px | 600 |
| Labels de campo | Inter | 12px | 500 |

---

## Espaciado y Radios

```
Padding de celdas en tabla:     10px 10px (póliza), 8px 10px (plan), 6px 10px (recibo)
Padding indentación nivel 0:    padding-left: 8px
Padding indentación nivel 1:    padding-left: 40px
Padding indentación nivel 2:    padding-left: 56px
Padding indentación nivel 3:    padding-left: 72px
Border radius badges:           4px
Border radius panel lateral:    0 (es un slide-in flush)
Border radius modales:          10px
Border radius botones:          6px
Border radius tarjetas endoso:  7px
Sombra panel lateral:           -4px 0 20px rgba(0,0,0,0.07)
Sombra modal:                   0 20px 60px rgba(0,0,0,0.2)
```

---

## Componentes SLDS recomendados

| Elemento diseñado | Componente SLDS / LWC |
|---|---|
| Sub-tabs Seguros/Fianzas | `lightning-tabset` + `lightning-tab` |
| Badges de estado | `lightning-badge` o `<span>` con CSS custom |
| Barra de progreso | `lightning-progress-bar` |
| Input de búsqueda | `lightning-input` type="search" |
| Select de filtro | `lightning-combobox` |
| Panel lateral | Custom LWC con `position: absolute` |
| Modal de renovación | `lightning-modal` (API nativa) |
| Toast de confirmación | `ShowToastEvent` |
| Árbol expandible | `lightning-tree-grid` (limitado) o tabla custom |
| Formulario de detalle | `lightning-record-view-form` + `lightning-output-field` |

> **Nota sobre `lightning-tree-grid`:** Soporta 2 niveles de anidamiento. Para 3 niveles (Póliza → Plan → Recibo) se recomienda una tabla custom con `tr` anidados controlados por JS, como está en el prototipo.

---

## Objetos Salesforce Involucrados

| Objeto | API Name | Relación |
|---|---|---|
| Seguro | `Seguro__c` | Raíz para seguros |
| Fianza | `Fianza__c` | Raíz para fianzas |
| Endoso de Seguro | `Endoso_de_Seguro__c` | M-D 1:N → Seguro__c |
| Endoso de Fianza | `Endoso_de_Fianza__c` | M-D 1:N → Fianza__c |
| Plan de Pagos | `Plan_de_Pagos__c` | M-D 1:N → Seguro__c o Fianza__c |
| Recibo de Cobro | `Recibo_de_Cobro__c` | M-D 1:N → Plan_de_Pagos__c |
| Contrato de Fianza | `Contrato__c` | Padre de Fianza (requiere diseño) |
| Convenio Modificatorio | `Convenio_Modificatorio__c` | Hijo de Contrato (requiere diseño) |
| Tabla de Comisiones | `Tech_Comision__c` | Maestro anual (requiere diseño) |
| Comisión | `Comision__c` | 1:N → Seguro/Fianza, se libera al cobrar |

---

## Elementos que requieren diseño adicional

Los siguientes objetos están en el modelo de datos pero **no tienen pantalla diseñada aún**:

1. **Contrato de Fianza (`Contrato__c`)** — Padre de las Fianzas. Campos: Beneficiario, Suma afianzada, Exposición %, Valor Contrato Vigente, Fin Contrato Vigente.
2. **Convenio Modificatorio** — Hijo del Contrato. Campos: Ampliación/Cambio de alcance.
3. **Tabla de Comisiones** — Maestro anual por Aseguradora × Ramo. Libera comisión al cobrar recibo.

---

## Archivos en este paquete

| Archivo | Descripción |
|---|---|
| `README.md` | Este documento |
| `Módulo Pólizas.html` | Prototipo interactivo principal (abrir en navegador) |
| `polizas-variacion-a.jsx` | Componente React del diseño de tabla (referencia) |
| `polizas-variacion-b.jsx` | Variación alternativa con cards (descartada, solo referencia) |
| `polizas-data.js` | Mock data con estructura de objetos Salesforce |
| `design-canvas.jsx` | Canvas de presentación (no relevante para implementación) |
| `tweaks-panel.jsx` | Panel de tweaks (no relevante para implementación) |

---

## Cómo usar este handoff

1. Abre `Módulo Pólizas.html` en un navegador para ver el prototipo interactivo
2. Lee este README para entender la lógica, tokens y estructura
3. Usa `polizas-variacion-a.jsx` como referencia de componentes y lógica de estado
4. Usa `polizas-data.js` para entender la forma del dato que debes consultar con SOQL
5. Implementa en LWC siguiendo las recomendaciones de componentes SLDS arriba

---

*Diseño generado el 03/05/2026 para Ollin Protección — Proyecto de migración Airtable → Salesforce*
