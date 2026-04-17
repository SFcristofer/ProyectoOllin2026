public with sharing class TechAfianzadoController {
    @AuraEnabled(cacheable=true)
    public static List<TechAfianzadoWrapper> getAfianzadosList() {
        List<TechAfianzadoWrapper> wrappers = new List<TechAfianzadoWrapper>();
        for (Account a : TechAfianzadoSelector.getRecentAfianzados()) {
            wrappers.add(new TechAfianzadoWrapper(a));
        }
        return wrappers;
    }
}
