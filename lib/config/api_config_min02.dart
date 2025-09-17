class ApiConfig_mina2 {
  static const String baseUrl = 'https://backend-seminco-pro-02.vercel.app/api';
      //'https://backend-seminco-mina-02.onrender.com/api';
      // 'https://backendseminco-production.up.railway.app/api';
  static const String loginEndpoint =
      '/auth/login'; // Asegurando que el endpoint es correcto
  static const String formatoPlanMineralEndpoint = '/PlanMineral/PlanMineral';
  static const String estadosEndpoint = '/estado/con-subestados';
  static const String PlanMensualEndpoint = '/PlamMensual/';
  static const String tipoPerforacionEndpoint = '/TipoPerfpo/';
  static const String EquipoEndpoint = '/Equipo/';
  static const String EmpresaEndpoint = '/Empresa/';
  static const String ExplosivoEndpoint = '/Explosivos/';
  static const String AccesorioEndpoint = '/Accesorios/';
  static const String explosivosUniEndpoint = '/Explo-uni/';
  static const String destinatarioCorreoEndpoint = '/Despacho-Destinatario/';
  static const String PlanProduccionEndpoint = '/PlanProduccion/';
  static const String PlanMetrajeEndpoint = '/PlanMetraje/';
  static const String fechasPlanMensualEndpoint = '/fechas-plan-mensual/';

  static const String operacionLargoEndpoint = '/operacion/largo';
  static const String operacionLargoEndpointactua = '/operacion/update-largo';
  static const String operacionHorizontalEndpoint = '/operacion/horizontal';
  static const String operacionHorizontalEndpointActualiza =
      '/operacion/update-horizontal';
  static const String operacionSostenimientoEndpoint =
      '/operacion/sostenimiento';
  static const String operacionSostenimientoEndpointActualiza =
      '/operacion/update-sostenimiento';

  static const String operacioncarguioEndpoint =
      '/operacion/carguio';
  static const String datosExploracionesEndpoint = '/NubeDatosExploraciones';
    static const String datosExploracionesmedionesEndpoint = '/NubeDatosExploraciones/Explo-medicion';
  static const String perforacionEndpoint = '/mediciones';

  static const String medicionesHorizontalEndpoint = '/medicion-tal-horizontal';
  static const String medicionesLargoEndpoint = '/medicion-tal-largo';
  static const String toneladasEndpoint = '/toneladas';
  static const String checklistEndpoint = '/check-list';
  static const String pdfEndpoint = '/pdf-operacion';
  static const String origenDestinoEndpoint = '/origen-destino';
}
