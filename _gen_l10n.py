# -*- coding: utf-8 -*-
# One-off generator: write the missing locale .yml files for modsSettingsApi,
# matching the language set used by Custom Sixth Sense. Run with Python 3.
import os

OUT = r'D:\aslain.modssettingsapi\sources\mods\aslain.modssettingsapi\text'

KEYS = [
    'name', 'description',
    'buttons/ok', 'buttons/cancel', 'buttons/apply', 'buttons/close',
    'buttons/clear', 'buttons/default',
    'stateswitcher/tooltip/header', 'stateswitcher/tooltip/body',
    'colorchoice/header',
]

T = {
 'bg': ['Конфигуратор на модове', 'Този мод позволява лесно конфигуриране на инсталираните модове.', 'OK', 'Отказ', 'Приложи', 'ЗАТВОРИ', 'Изчисти', 'По подразбиране', 'Включи / Изключи мод', 'Зелен индикатор - мод включен\\nЧервен индикатор - мод изключен', 'ЦВЯТ'],
 'cs': ['Konfigurátor modů', 'Tento mod umožňuje snadno konfigurovat nainstalované mody.', 'OK', 'Zrušit', 'Použít', 'ZAVŘÍT', 'Vymazat', 'Výchozí', 'Zapnout / Vypnout mod', 'Zelený indikátor - mod zapnut\\nČervený indikátor - mod vypnut', 'BARVA'],
 'da': ['Mod-konfigurator', 'Dette mod giver dig mulighed for nemt at konfigurere installerede mods.', 'OK', 'Annuller', 'Anvend', 'LUK', 'Ryd', 'Standard', 'Aktivér / Deaktivér mod', 'Grøn indikator - mod aktiveret\\nRød indikator - mod deaktiveret', 'FARVE'],
 'el': ['Διαμορφωτής mod', 'Αυτό το mod σάς επιτρέπει να ρυθμίζετε εύκολα τα εγκατεστημένα mod.', 'OK', 'Άκυρο', 'Εφαρμογή', 'ΚΛΕΙΣΙΜΟ', 'Εκκαθάριση', 'Προεπιλογή', 'Ενεργοποίηση / Απενεργοποίηση mod', 'Πράσινη ένδειξη - το mod είναι ενεργό\\nΚόκκινη ένδειξη - το mod είναι ανενεργό', 'ΧΡΩΜΑ'],
 'es': ['Configurador de mods', 'Este mod te permite configurar fácilmente los mods instalados.', 'OK', 'Cancelar', 'Aplicar', 'CERRAR', 'Borrar', 'Predeterminado', 'Activar / Desactivar mod', 'Indicador verde - mod activado\\nIndicador rojo - mod desactivado', 'COLOR'],
 'fi': ['Modien määritys', 'Tämä modi mahdollistaa asennettujen modien helpon määrittämisen.', 'OK', 'Peruuta', 'Käytä', 'SULJE', 'Tyhjennä', 'Oletus', 'Ota modi käyttöön / poista käytöstä', 'Vihreä ilmaisin - modi käytössä\\nPunainen ilmaisin - modi pois käytöstä', 'VÄRI'],
 'fr': ['Configurateur de mods', 'Ce mod vous permet de configurer facilement les mods installés.', 'OK', 'Annuler', 'Appliquer', 'FERMER', 'Effacer', 'Par défaut', 'Activer / Désactiver le mod', 'Indicateur vert - mod activé\\nIndicateur rouge - mod désactivé', 'COULEUR'],
 'hr': ['Konfigurator modova', 'Ovaj mod omogućuje jednostavno konfiguriranje instaliranih modova.', 'OK', 'Odustani', 'Primijeni', 'ZATVORI', 'Očisti', 'Zadano', 'Omogući / Onemogući mod', 'Zeleni indikator - mod omogućen\\nCrveni indikator - mod onemogućen', 'BOJA'],
 'it': ['Configuratore di mod', 'Questo mod ti permette di configurare facilmente i mod installati.', 'OK', 'Annulla', 'Applica', 'CHIUDI', 'Cancella', 'Predefinito', 'Attiva / Disattiva mod', 'Indicatore verde - mod attivato\\nIndicatore rosso - mod disattivato', 'COLORE'],
 'lt': ['Modų konfigūratorius', 'Šis modas leidžia lengvai konfigūruoti įdiegtus modus.', 'OK', 'Atšaukti', 'Taikyti', 'UŽDARYTI', 'Išvalyti', 'Numatytasis', 'Įjungti / Išjungti modą', 'Žalias indikatorius - modas įjungtas\\nRaudonas indikatorius - modas išjungtas', 'SPALVA'],
 'lv': ['Modu konfigurators', 'Šis mods ļauj viegli konfigurēt instalētos modus.', 'OK', 'Atcelt', 'Lietot', 'AIZVĒRT', 'Notīrīt', 'Noklusējums', 'Iespējot / Atspējot modu', 'Zaļš indikators - mods iespējots\\nSarkans indikators - mods atspējots', 'KRĀSA'],
 'nl': ['Mod-configurator', 'Met deze mod kun je geïnstalleerde mods eenvoudig configureren.', 'OK', 'Annuleren', 'Toepassen', 'SLUITEN', 'Wissen', 'Standaard', 'Mod inschakelen / uitschakelen', 'Groene indicator - mod ingeschakeld\\nRode indicator - mod uitgeschakeld', 'KLEUR'],
 'no': ['Mod-konfigurator', 'Denne moden lar deg enkelt konfigurere installerte mods.', 'OK', 'Avbryt', 'Bruk', 'LUKK', 'Tøm', 'Standard', 'Aktiver / Deaktiver mod', 'Grønn indikator - mod aktivert\\nRød indikator - mod deaktivert', 'FARGE'],
 'pt': ['Configurador de mods', 'Este mod permite configurar facilmente os mods instalados.', 'OK', 'Cancelar', 'Aplicar', 'FECHAR', 'Limpar', 'Padrão', 'Ativar / Desativar mod', 'Indicador verde - mod ativado\\nIndicador vermelho - mod desativado', 'COR'],
 'ro': ['Configurator de moduri', 'Acest mod îți permite să configurezi cu ușurință modurile instalate.', 'OK', 'Anulează', 'Aplică', 'ÎNCHIDE', 'Șterge', 'Implicit', 'Activează / Dezactivează modul', 'Indicator verde - mod activat\\nIndicator roșu - mod dezactivat', 'CULOARE'],
 'sr': ['Konfigurator modova', 'Ovaj mod omogućava jednostavno konfigurisanje instaliranih modova.', 'OK', 'Otkaži', 'Primeni', 'ZATVORI', 'Očisti', 'Podrazumevano', 'Omogući / Onemogući mod', 'Zeleni indikator - mod omogućen\\nCrveni indikator - mod onemogućen', 'BOJA'],
 'sv': ['Mod-konfigurator', 'Denna mod låter dig enkelt konfigurera installerade mods.', 'OK', 'Avbryt', 'Tillämpa', 'STÄNG', 'Rensa', 'Standard', 'Aktivera / Inaktivera mod', 'Grön indikator - mod aktiverad\\nRöd indikator - mod inaktiverad', 'FÄRG'],
 'tr': ['Mod yapılandırıcı', 'Bu mod, yüklü modları kolayca yapılandırmanıza olanak tanır.', 'OK', 'İptal', 'Uygula', 'KAPAT', 'Temizle', 'Varsayılan', 'Modu etkinleştir / devre dışı bırak', 'Yeşil gösterge - mod etkin\\nKırmızı gösterge - mod devre dışı', 'RENK'],
}

for lang, vals in sorted(T.items()):
    assert len(vals) == len(KEYS), lang
    lines = ['%s: %s' % (k, v) for k, v in zip(KEYS, vals)]
    content = '\r\n'.join(lines) + '\r\n'
    with open(os.path.join(OUT, lang + '.yml'), 'w', encoding='utf-8', newline='') as f:
        f.write(content)
    print('wrote', lang + '.yml')

print('done', len(T), 'files')
