# Arquitectura de Datos — Proyecto Ollin 2026
**Fecha:** Abril 2026 | **Plataforma:** Salesforce CRM

---

## ¿Qué hace el sistema?

El sistema gestiona el ciclo completo de **afianzamiento de obra**: desde la evaluación de un contratista (precalificación), pasando por la emisión de fianzas y firma de contratos, hasta el seguimiento de proyectos y beneficiarios. Todo integrado en una sola vista estilo Airtable dentro de Salesforce.

---

## Los 9 objetos del modelo

| Objeto | Rol en el negocio |
|--------|-------------------|
| **Account (Cliente/Afianzado)** | Empresa o persona que solicita la fianza. Puede ser tanto el cliente que contrata la obra como el afianzado ante la aseguradora. |
| **Contratista** | Empresa constructora o prestadora de servicios que ejecuta la obra. Ahora vinculada directamente a su Cliente. |
| **Fianza** | La garantía emitida. Núcleo del sistema: conecta contratistas, contratos, beneficiarios y vendedores. |
| **Contrato** | El acuerdo formal bajo el cual se ejecuta la obra. Relacionado a fianzas y al contratista ejecutor. |
| **Proyecto** | La obra física. Cada proyecto pertenece a un contrato específico. |
| **Beneficiario** | Quien se beneficia de la garantía en caso de incumplimiento (ej. dueño de la obra, dependencia gubernamental). |
| **Precalificación** | Evaluación financiera del contratista: capital contable, capacidad de afianzamiento, score ICP. Determina si puede ser afianzado. |
| **Ampliación (Endoso)** | Modificación o extensión de una fianza existente. Vinculada directamente a la fianza original. |
| **Vendedor** | Ejecutivo comercial que gestiona la relación y aparece en fianzas y contratos. |

---

## Cómo se relacionan los objetos

```
Cliente (Account)
│
├── es contratado por ──→ Contratista ──→ tiene muchas ──→ Fianzas
│                              │                                │
│                              └── tiene muchas ──→ Precalificaciones
│                              └── tiene muchos ──→ Contratos (vía junction)
│
└── es afianzado ante ──→ Fianza
                              │
                              ├── pertenece a ──→ Contrato
                              │                       │
                              │                       └── tiene muchos ──→ Proyectos
                              │                                                │
                              │                                                └── tiene ──→ Beneficiarios
                              │
                              ├── cubre a ──→ Beneficiario
                              ├── fue vendida por ──→ Vendedor
                              └── puede tener ──→ Ampliaciones (Endosos)
```

---

## Principio de diseño: directo vs. flexible

El modelo usa **dos mecanismos de relación**, cada uno donde tiene sentido:

### Relaciones directas (lookup)
Se usan cuando la respuesta es siempre "uno a uno" o "muchos a uno". Son rápidas, simples y directas.

| Relación | Significado |
|----------|-------------|
| Fianza → Contratista | Una fianza tiene **un** contratista ejecutor |
| Fianza → Vendedor | Una fianza tiene **un** vendedor asignado |
| Contratista → Cliente | Un contratista trabaja para **un** cliente principal |
| Proyecto → Contrato | Un proyecto pertenece a **un** contrato |
| Precalificación → Contratista | Una precalificación evalúa a **un** contratista |
| Ampliación → Fianza | Una ampliación modifica **una** fianza |

### Relaciones flexibles (junction: Relación Técnica)
Se usan cuando la relación es "muchos a muchos" o puede evolucionar con el tiempo.

| Relación | Por qué es flexible |
|----------|---------------------|
| Contratista ↔ Contratos | Un contratista puede tener múltiples contratos y un contrato puede involucrar a múltiples partes |
| Fianza ↔ Contratos | Una fianza puede cubrir varios contratos |
| Proyecto ↔ Beneficiarios | Un proyecto puede tener múltiples beneficiarios |

---

## El campo Cliente en Contratista: ¿por qué importa?

Antes, no había forma directa de saber "¿para qué empresa trabaja este contratista?". La única ruta era: Contratista → Fianza → Afianzado, un camino indirecto y costoso.

Con el nuevo campo `Cliente` en Contratista:

- Se puede consultar directamente **"todos los contratistas del cliente Femsa"**
- El panel de detalle del contratista muestra y permite cambiar el cliente
- Abre la puerta a un futuro **panel de Cliente** que liste sus contratistas, contratos y fianzas activas en una sola vista

---

## Las 5 pestañas del sistema y qué muestran

| Pestaña | Datos principales | Relaciones visibles |
|---------|-------------------|---------------------|
| **Fianzas** | Número de fianza, monto, estatus, fecha de emisión | Contratista (directo), vendedor, contratos vinculados |
| **Ampliaciones** | Número de endoso, fianza original | Fianza principal |
| **Fianzas Globales** | Vista consolidada de todas las fianzas | — |
| **Contratos** | Número de contrato, fechas, monto | Contratista, fianzas vinculadas |
| **Proyectos** | Nombre del proyecto, contrato | Contrato (directo) |
| **Contratistas** | Nombre, RFC, cliente | Fianzas (directo), contratos, precalificaciones, cliente |
| **Beneficiarios** | Nombre, RFC | Fianzas y contratos vinculados |
| **Afianzados** | Nombre (Account), RFC | Fianzas solicitadas |

---

## Flujo típico de una operación

```
1. CLIENTE solicita afianzamiento para obra
         ↓
2. Se evalúa al CONTRATISTA (Precalificación)
   — Score ICP, capital contable, capacidad de afianzamiento
         ↓
3. Se firma el CONTRATO de obra
         ↓
4. Se emite la FIANZA
   — Vinculada al contratista, contrato y beneficiario
         ↓
5. Se registra el PROYECTO asociado al contrato
         ↓
6. Si hay modificaciones → se crea una AMPLIACIÓN de la fianza
         ↓
7. Al vencer → la fianza pasa a estado "Vencida"
   — Aparece en el panel de interfaces del contratista como fianza vencida
   — Se calculan días de reclamo disponibles
```

---

## Capacidades de consulta habilitadas

Gracias a la arquitectura actual, el sistema puede responder preguntas como:

- ¿Qué fianzas activas tiene el contratista X?
- ¿Cuánto monto afianzado acumula un contratista?
- ¿Qué precalificaciones tiene y cuál es su capacidad de afianzamiento?
- ¿Qué contratos están cubiertos por fianzas vencidas?
- ¿Para qué cliente trabaja cada contratista?
- ¿Qué proyectos están relacionados a un contrato con fianza activa?

---

## Lo que viene (Fase 2 sugerida)

| Mejora | Beneficio |
|--------|-----------|
| Campo `Contratista` en Contrato (lookup directo) | Eliminar dependencia del junction para contratos de un contratista |
| Campo `Cliente` en Contrato | Saber qué cliente celebró cada contrato sin pasar por la fianza |
| Panel de Cliente | Vista 360° del cliente: todos sus contratistas, contratos y fianzas activas |
| RFC en Contratista | Campo directo en lugar del placeholder "Ver en Salesforce" |

---

*Documento generado para el equipo directivo de Proyecto Ollin 2026*
