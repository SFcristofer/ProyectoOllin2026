public with sharing class TechPolizasWrapper {

    public class PolizaItem {
        @AuraEnabled public Id      id;
        @AuraEnabled public String  name;
        @AuraEnabled public String  tipo;
        @AuraEnabled public String  cliente;
        @AuraEnabled public String  beneficiario;
        @AuraEnabled public String  aseguradora;
        @AuraEnabled public String  ramo;
        @AuraEnabled public String  vendedor;
        @AuraEnabled public Id      vendedorId;
        @AuraEnabled public String  vendedorNombre;
        @AuraEnabled public String  vendedorEmail;
        @AuraEnabled public Decimal prima;
        // Fianza-specific
        @AuraEnabled public Decimal montoAfianzado;
        @AuraEnabled public Decimal montoAfianzadoVigente;
        @AuraEnabled public Decimal primaVigente;
        @AuraEnabled public String  fechaVencimientoVigente;
        @AuraEnabled public Decimal exposicion;
        // Dates
        @AuraEnabled public String  vigenciaInicio;
        @AuraEnabled public String  vigenciaFin;
        @AuraEnabled public Integer diasParaVencer;
        @AuraEnabled public String  estatus;
        // Related data
        @AuraEnabled public ContratoInfo           contrato;
        @AuraEnabled public List<RelacionItem>     relaciones;
        @AuraEnabled public List<EndosoItem>       endosos;
        @AuraEnabled public List<ConvenioItem>     convenios;
        @AuraEnabled public List<ComisionItem>     comisiones;
        @AuraEnabled public PlanItem               planPago;
    }

    public class ContratoInfo {
        @AuraEnabled public Id      id;
        @AuraEnabled public String  name;
        @AuraEnabled public String  estatus;
        @AuraEnabled public String  contratista;
        @AuraEnabled public String  beneficiario;
        @AuraEnabled public String  institucion;
        @AuraEnabled public String  vendedor;
        @AuraEnabled public String  proyecto;
        @AuraEnabled public Decimal valorVigente;
        @AuraEnabled public String  finVigente;
        @AuraEnabled public Decimal sumaFianzas;
        @AuraEnabled public Decimal exposicion;
    }

    public class RelacionItem {
        @AuraEnabled public Id     id;
        @AuraEnabled public String tipo;
        @AuraEnabled public String nombre;
    }

    public class ConvenioItem {
        @AuraEnabled public Id      id;
        @AuraEnabled public String  name;
        @AuraEnabled public String  fecha;
        @AuraEnabled public String  tipo;
        @AuraEnabled public String  descripcion;
        @AuraEnabled public Decimal nuevoValor;
        @AuraEnabled public String  nuevaFechaFin;
        @AuraEnabled public Decimal diferencia;
    }

    public class ComisionItem {
        @AuraEnabled public Id      id;
        @AuraEnabled public String  name;
        @AuraEnabled public String  vendedor;
        @AuraEnabled public Decimal pctAplicado;
        @AuraEnabled public Decimal montoOllin;
        @AuraEnabled public Decimal montoVendedor;
        @AuraEnabled public String  estatus;
    }

    public class EndosoItem {
        @AuraEnabled public Id      id;
        @AuraEnabled public String  name;
        @AuraEnabled public String  fechaEfectiva;
        @AuraEnabled public Decimal diferenciaMonto;
        @AuraEnabled public String  estado;
        @AuraEnabled public String  tipoEndoso;
        @AuraEnabled public Decimal nuevoMonto;
        @AuraEnabled public String  finVigencia;
        @AuraEnabled public String  convenioNombre;
        @AuraEnabled public Decimal nuevaPrima;
        @AuraEnabled public String  motivo;
        @AuraEnabled public String  observaciones;
        @AuraEnabled public Boolean afectaPrima;
        @AuraEnabled public String  nuevaModalidad;
        @AuraEnabled public String  finContrato;
    }

    public class PlanItem {
        @AuraEnabled public Id      id;
        @AuraEnabled public String  name;
        @AuraEnabled public String  metodoPago;
        @AuraEnabled public String  periodoPago;
        @AuraEnabled public String  fechaInicio;
        @AuraEnabled public Integer numRecibos;
        @AuraEnabled public String  estado;
        @AuraEnabled public List<ReciboItem> recibos;
    }

    public class ReciboItem {
        @AuraEnabled public Id      id;
        @AuraEnabled public String  name;
        @AuraEnabled public Integer numero;
        @AuraEnabled public Decimal monto;
        @AuraEnabled public Decimal montoCobrado;
        @AuraEnabled public Decimal saldo;
        @AuraEnabled public String  fechaVencimiento;
        @AuraEnabled public String  fechaPago;
        @AuraEnabled public String  estado;
        @AuraEnabled public String  metodoPago;
        @AuraEnabled public String  referenciaPago;
        @AuraEnabled public Integer intentosContacto;
        @AuraEnabled public String  motivoNoPago;
    }

    public class VendedorOption {
        @AuraEnabled public Id     id;
        @AuraEnabled public String nombre;
        @AuraEnabled public String email;
    }

    public class AccountOption {
        @AuraEnabled public Id     id;
        @AuraEnabled public String name;
        @AuraEnabled public String ciudad;
    }

    public class ContratoOption {
        @AuraEnabled public Id      id;
        @AuraEnabled public String  contractNumber;
        @AuraEnabled public String  status;
        @AuraEnabled public Decimal valor;
        @AuraEnabled public String  proyecto;
    }
}