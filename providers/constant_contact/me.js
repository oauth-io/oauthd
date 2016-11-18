var me = {
    url: "/account/info",
    fields: {
        "name": function(me) {
            return me.first_name + ' ' + me.last_name;
        },
        "website":"website",
        "organization_name":"organization_name",
        "time_zone":"time_zone",
        "first_name":"first_name",
        "last_name":"last_name",
        "phone":"phone",
        "company_logo":"company_logo",
        "country_code":"country_code",
        "state_code":"state_code",
        "organization_addresses": "organization_addresses"
    }
};
module.exports = me;