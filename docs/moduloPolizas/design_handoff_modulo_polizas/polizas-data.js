// Mock data for Ollin Seguros - Módulo Pólizas v2
const MOCK_DATA = {
  seguros: [
    {
      id: "seg-001",
      folio: "Seguro - JUAN LUIS RUIZ BAUTISTA - Seguros de auto",
      cliente: "JUAN LUIS RUIZ BAUTISTA",
      ramo: "Auto",
      producto: "Auto 2",
      aseguradora: "GNP Seguros",
      vendedor: "V-0010",
      comision: 9,
      prima: 50000,
      vigenciaInicio: "31/05/2026",
      vigenciaFin: "31/05/2027",
      diasParaVencer: 28,
      estatus: "Emitida",
      oportunidad: "JUAN LUIS RUIZ BAUTISTA - Seguros de auto",
      endosos: [
        { id: "end-001", folio: "Endoso-001", tipo: "Cambio de cobertura", fechaEfectiva: "15/06/2026", diferenciaMonto: 2500, estatus: "Activo" }
      ],
      planPago: {
        id: "pp-001",
        folio: "Plan_Pago_00136",
        metodoPago: "Efectivo",
        periodoPago: "Mensual",
        fechaInicio: "31/05/2026",
        numRecibos: 12,
        estatus: "Activo",
        recibos: [
          { id: "r-001", folio: "Recibo_Pago_1342", monto: 4500, fechaVencimiento: "31/05/2026", estatus: "Pendiente" },
          { id: "r-002", folio: "Recibo_Pago_1343", monto: 4500, fechaVencimiento: "30/06/2026", estatus: "Pendiente" },
          { id: "r-003", folio: "Recibo_Pago_1344", monto: 4500, fechaVencimiento: "31/07/2026", estatus: "Pendiente" },
          { id: "r-004", folio: "Recibo_Pago_1345", monto: 4500, fechaVencimiento: "31/08/2026", estatus: "Pendiente" },
          { id: "r-005", folio: "Recibo_Pago_1346", monto: 4500, fechaVencimiento: "30/09/2026", estatus: "Pendiente" },
          { id: "r-006", folio: "Recibo_Pago_1347", monto: 4500, fechaVencimiento: "31/10/2026", estatus: "Pendiente" },
          { id: "r-007", folio: "Recibo_Pago_1348", monto: 4500, fechaVencimiento: "30/11/2026", estatus: "Pendiente" },
          { id: "r-008", folio: "Recibo_Pago_1349", monto: 4500, fechaVencimiento: "31/12/2026", estatus: "Pendiente" },
          { id: "r-009", folio: "Recibo_Pago_1350", monto: 4500, fechaVencimiento: "31/01/2027", estatus: "Pendiente" },
          { id: "r-010", folio: "Recibo_Pago_1351", monto: 4500, fechaVencimiento: "28/02/2027", estatus: "Pendiente" },
          { id: "r-011", folio: "Recibo_Pago_1352", monto: 4500, fechaVencimiento: "31/03/2027", estatus: "Pendiente" },
          { id: "r-012", folio: "Recibo_Pago_1353", monto: 4500, fechaVencimiento: "30/04/2027", estatus: "Pendiente" }
        ]
      }
    },
    {
      id: "seg-002",
      folio: "Renovación - JORGE MORENO - Auto",
      cliente: "Jorge Moreno",
      ramo: "Auto",
      producto: "Auto 2",
      aseguradora: "Qualitas",
      vendedor: "Carlos Mendoza",
      comision: 12,
      prima: 12555,
      vigenciaInicio: "01/05/2026",
      vigenciaFin: "01/05/2027",
      diasParaVencer: 362,
      estatus: "Emitida",
      oportunidad: "Renovación - JORGE MORENO - Auto",
      endosos: [],
      planPago: {
        id: "pp-002",
        folio: "Plan_Pago_00128",
        metodoPago: "Transferencia SPEI",
        periodoPago: "Mensual",
        fechaInicio: "01/05/2026",
        numRecibos: 12,
        estatus: "Activo",
        recibos: [
          { id: "r-101", folio: "Recibo_Pago_1280", monto: 1130, fechaVencimiento: "01/05/2026", estatus: "Pagado" },
          { id: "r-102", folio: "Recibo_Pago_1281", monto: 1130, fechaVencimiento: "01/06/2026", estatus: "Pagado" },
          { id: "r-103", folio: "Recibo_Pago_1282", monto: 1130, fechaVencimiento: "01/07/2026", estatus: "Pendiente" },
          { id: "r-104", folio: "Recibo_Pago_1283", monto: 1130, fechaVencimiento: "01/08/2026", estatus: "Pendiente" }
        ]
      }
    },
    {
      id: "seg-003",
      folio: "Seguro de autos - moreno",
      cliente: "moreno",
      ramo: "Auto",
      producto: "Auto 2",
      aseguradora: "Acuaseguros Plus",
      vendedor: "Carlos Mendoza",
      comision: 0,
      prima: 50000,
      vigenciaInicio: "04/05/2026",
      vigenciaFin: "04/05/2027",
      diasParaVencer: 366,
      estatus: "Emitida",
      oportunidad: "Seguro de autos 25",
      endosos: [
        { id: "end-002", folio: "Endoso-002", tipo: "Inclusión de conductor", fechaEfectiva: "10/05/2026", diferenciaMonto: 800, estatus: "Activo" },
        { id: "end-003", folio: "Endoso-003", tipo: "Cambio de domicilio", fechaEfectiva: "20/05/2026", diferenciaMonto: 0, estatus: "Activo" }
      ],
      planPago: {
        id: "pp-003",
        folio: "Plan_Pago_00130",
        metodoPago: "Tarjeta crédito/débito",
        periodoPago: "Mensual",
        fechaInicio: "04/05/2026",
        numRecibos: 12,
        estatus: "Activo",
        recibos: [
          { id: "r-201", folio: "Recibo_Pago_1290", monto: 4500, fechaVencimiento: "04/05/2026", estatus: "Vencido" },
          { id: "r-202", folio: "Recibo_Pago_1291", monto: 4500, fechaVencimiento: "04/06/2026", estatus: "Pendiente" },
          { id: "r-203", folio: "Recibo_Pago_1292", monto: 4500, fechaVencimiento: "04/07/2026", estatus: "Pendiente" }
        ]
      }
    }
  ],
  fianzas: [
    {
      id: "fi-001",
      folio: "Oportunidad Fianza - Jorge Moreno",
      cliente: "Jorge Moreno",
      ramo: "Fianza",
      producto: "Fianza de fidelidad",
      aseguradora: "Chubb",
      vendedor: "Carlos Mendoza",
      comision: 8,
      prima: 12000,
      vigenciaInicio: "01/05/2026",
      vigenciaFin: "01/05/2027",
      diasParaVencer: 363,
      estatus: "Emitida",
      oportunidad: "Oportunidad Fianza",
      endosos: [],
      contrato: { id: "ct-001", folio: "Contrato-001", beneficiario: "Empresa ABC", montoAfianzado: 500000 },
      planPago: {
        id: "pp-004",
        folio: "Plan_Pago_00140",
        metodoPago: "Contado",
        periodoPago: "Anual",
        fechaInicio: "01/05/2026",
        numRecibos: 1,
        estatus: "Activo",
        recibos: [
          { id: "r-301", folio: "Recibo_Pago_1400", monto: 12000, fechaVencimiento: "01/05/2026", estatus: "Pagado" }
        ]
      }
    },
    {
      id: "fi-002",
      folio: "Jorge PPR - Fianza",
      cliente: "Jorge Moreno",
      ramo: "PPR",
      producto: "PPR",
      aseguradora: "Mapfre",
      vendedor: "Carlos Mendoza",
      comision: 5,
      prima: 15000,
      vigenciaInicio: "30/04/2026",
      vigenciaFin: "30/04/2027",
      diasParaVencer: 362,
      estatus: "Emitida",
      oportunidad: "Jorge PPR",
      endosos: [
        { id: "end-004", folio: "Endoso-004", tipo: "Ampliación de plazo", fechaEfectiva: "01/06/2026", diferenciaMonto: 1200, estatus: "Activo" }
      ],
      planPago: {
        id: "pp-005",
        folio: "Plan_Pago_00141",
        metodoPago: "Transferencia SPEI",
        periodoPago: "Semestral",
        fechaInicio: "30/04/2026",
        numRecibos: 2,
        estatus: "Activo",
        recibos: [
          { id: "r-401", folio: "Recibo_Pago_1410", monto: 7500, fechaVencimiento: "30/04/2026", estatus: "Vencido" },
          { id: "r-402", folio: "Recibo_Pago_1411", monto: 7500, fechaVencimiento: "30/10/2026", estatus: "Pendiente" }
        ]
      }
    }
  ]
};

Object.assign(window, { MOCK_DATA });
