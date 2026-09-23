Locales = {
    en = {
        title = 'Vehicle cleanup',
        warning = 'Unused vehicles will be removed in %s seconds. Get in your vehicle or stay close to keep it.',
        done = '%s vehicle(s) removed. Next cleanup in %s min.',
        nothing = 'Nothing to remove. Next cleanup in %s min.',
        forced = 'An admin brought the cleanup forward: unused vehicles will be removed in %s seconds.',
        forced_admin = 'Cleanup in %s seconds',
        protected = 'Vehicle protected from cleanup',
        unprotected = 'Vehicle no longer protected',
        not_in_vehicle = 'You must be inside a vehicle',
        next = 'Next cleanup in %d:%02d',
        last = 'Last one (%d min ago): %s removed, %s kept',
        no_last = 'No cleanup has run since the resource started',
    },
    es = {
        title = 'Limpieza de vehiculos',
        warning = 'Los vehiculos sin uso se borraran en %s segundos. Sube a tu coche o quedate cerca para conservarlo.',
        done = '%s vehiculo(s) borrado(s). Proxima limpieza en %s min.',
        nothing = 'Nada que borrar. Proxima limpieza en %s min.',
        forced = 'Un admin ha adelantado la limpieza: los vehiculos sin uso se borran en %s segundos.',
        forced_admin = 'Limpieza en %s segundos',
        protected = 'Vehiculo protegido de la limpieza',
        unprotected = 'Vehiculo desprotegido',
        not_in_vehicle = 'Tienes que estar dentro de un vehiculo',
        next = 'Proxima limpieza en %d:%02d',
        last = 'Ultima (hace %d min): %s borrados, %s salvados',
        no_last = 'Todavia no ha pasado ninguna limpieza desde el arranque',
    },
}

function L(key, ...)
    local strings = Locales[Config.Locale] or Locales.en
    local text = strings[key] or Locales.en[key] or key
    return select('#', ...) > 0 and text:format(...) or text
end
