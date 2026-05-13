public with sharing class TechInstitucionController {

    public class EjecutivoDto {
        @AuraEnabled public String  id;
        @AuraEnabled public String  name;
        @AuraEnabled public String  puesto;
        @AuraEnabled public String  area;
        @AuraEnabled public String  email;
        @AuraEnabled public String  telefono;
        @AuraEnabled public String  celular;
        @AuraEnabled public Boolean esPrincipal;
    }

    public class AccesoDto {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String urlPortal;
        @AuraEnabled public String tipoPortal;
        @AuraEnabled public String usuario;
        @AuraEnabled public String notas;
    }

    public class InstitucionDto {
        @AuraEnabled public String             id;
        @AuraEnabled public String             name;
        @AuraEnabled public String             tipo;
        @AuraEnabled public String             estatus;
        @AuraEnabled public String             sitioWeb;
        @AuraEnabled public String             ejecutivoPrincipal;
        @AuraEnabled public Integer            totalEjecutivos;
        @AuraEnabled public List<EjecutivoDto> ejecutivos;
        @AuraEnabled public List<AccesoDto>    accesos;
    }

    @AuraEnabled(cacheable=true)
    public static List<InstitucionDto> getInstitucionList() {
        List<Institucion__c> instituciones = [
            SELECT Id, Name, Tipo__c, Estatus__c, Pagina_Web__c
            FROM   Institucion__c
            ORDER BY Name ASC
            LIMIT  500
        ];

        if (instituciones.isEmpty()) return new List<InstitucionDto>();

        Set<Id> ids = (new Map<Id, Institucion__c>(instituciones)).keySet();

        Map<Id, List<Acceso_al_portal__c>> accMap = new Map<Id, List<Acceso_al_portal__c>>();
        for (Acceso_al_portal__c acc : [
            SELECT Id, Name, URL_del_portal__c, Tipo_de_portal__c, Usuario__c, Notas__c, Institucion__c
            FROM   Acceso_al_portal__c
            WHERE  Institucion__c IN :ids
            ORDER BY Name ASC
        ]) {
            if (!accMap.containsKey(acc.Institucion__c)) {
                accMap.put(acc.Institucion__c, new List<Acceso_al_portal__c>());
            }
            accMap.get(acc.Institucion__c).add(acc);
        }

        Map<Id, List<EjecutivoContacto__c>> ejMap = new Map<Id, List<EjecutivoContacto__c>>();
        for (EjecutivoContacto__c ej : [
            SELECT Id, Name, Puesto__c, Area__c, Email__c, Telefono__c, Celular__c,
                   Principal__c, Institucion__c
            FROM   EjecutivoContacto__c
            WHERE  Institucion__c IN :ids
            ORDER BY Principal__c DESC NULLS LAST, Name ASC
        ]) {
            if (!ejMap.containsKey(ej.Institucion__c)) {
                ejMap.put(ej.Institucion__c, new List<EjecutivoContacto__c>());
            }
            ejMap.get(ej.Institucion__c).add(ej);
        }

        List<InstitucionDto> result = new List<InstitucionDto>();
        for (Institucion__c inst : instituciones) {
            InstitucionDto dto    = new InstitucionDto();
            dto.id                = inst.Id;
            dto.name              = inst.Name;
            dto.tipo              = inst.Tipo__c;
            dto.estatus           = inst.Estatus__c;
            dto.sitioWeb          = inst.Pagina_Web__c;
            dto.ejecutivoPrincipal = '';
            dto.ejecutivos        = new List<EjecutivoDto>();
            dto.accesos           = new List<AccesoDto>();

            List<Acceso_al_portal__c> accList = accMap.containsKey(inst.Id)
                ? accMap.get(inst.Id)
                : new List<Acceso_al_portal__c>();

            for (Acceso_al_portal__c acc : accList) {
                AccesoDto aDto  = new AccesoDto();
                aDto.id         = acc.Id;
                aDto.name       = acc.Name;
                aDto.urlPortal  = acc.URL_del_portal__c;
                aDto.tipoPortal = acc.Tipo_de_portal__c;
                aDto.usuario    = acc.Usuario__c;
                aDto.notas      = acc.Notas__c;
                dto.accesos.add(aDto);
            }

            List<EjecutivoContacto__c> ejList = ejMap.containsKey(inst.Id)
                ? ejMap.get(inst.Id)
                : new List<EjecutivoContacto__c>();

            dto.totalEjecutivos = ejList.size();

            for (EjecutivoContacto__c ej : ejList) {
                EjecutivoDto ejDto  = new EjecutivoDto();
                ejDto.id            = ej.Id;
                ejDto.name          = ej.Name;
                ejDto.puesto        = ej.Puesto__c;
                ejDto.area          = ej.Area__c;
                ejDto.email         = ej.Email__c;
                ejDto.telefono      = ej.Telefono__c;
                ejDto.celular       = ej.Celular__c;
                ejDto.esPrincipal   = ej.Principal__c;
                dto.ejecutivos.add(ejDto);
                if (ej.Principal__c == true && String.isEmpty(dto.ejecutivoPrincipal)) {
                    dto.ejecutivoPrincipal = ej.Name;
                }
            }

            result.add(dto);
        }
        return result;
    }

    @AuraEnabled
    public static String verifyAndGetPassword(Id accesoId, String usuario, String contrasena) {
        List<OllinPortalAccess__mdt> records = [
            SELECT Usuario__c, Contrasena__c
            FROM   OllinPortalAccess__mdt
            LIMIT  1
        ];
        if (records.isEmpty()) {
            throw new AuraHandledException('No hay configuración de verificación registrada.');
        }
        OllinPortalAccess__mdt cfg = records[0];
        if (cfg.Usuario__c != usuario || cfg.Contrasena__c != contrasena) {
            throw new AuraHandledException('Credenciales incorrectas.');
        }
        Acceso_al_portal__c acc = [
            SELECT Pass__c FROM Acceso_al_portal__c WHERE Id = :accesoId LIMIT 1
        ];
        return acc.Pass__c;
    }
}