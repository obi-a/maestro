var ragios = {
    request : function(options) {
        $.ajax(options);
    },

    restart : function(monitor_id, success, error) {
        this.request({
            type: "PUT",
            url: "/monitors/" + monitor_id + "?status=active",
            success: success,
            error: error
        });
    },

    stop : function(monitor_id, success, error) {
        this.request({
            type: "PUT",
            url: "/monitors/" + monitor_id + "?status=stopped",
            success: success,
            error: error
        });
    },

    test : function(monitor_id, success, error) {
        var data = {id: monitor_id};
        this.request({
            type: "POST",
            url: "/tests/",
            success: success,
            error: error,
            data: data
        });
    },

    add : function(data, success, error) {
        this.request({
            type: "POST",
            url: "/monitors/",
            success: success,
             error: error,
             data: data
        });
    },

    delete : function(monitor_id, success, error) {
        this.request({
            type: "DELETE",
            url: "/monitors/" + monitor_id,
            success: success,
            error: error
        });
    },

    update : function (monitor_id, data, success, error) {
        this.request({
            type: "PUT",
            url: "/monitors/" + monitor_id,
            success: success,
            error: error,
            data: data,
            contentType: "application/json"
        });
    },

    find : function(monitor_id, success, error) {
        this.request({
            type: "GET",
            url: "/monitors/" + monitor_id,
            success: success,
            error: error,
        });
    },

    getNotifications : function(monitor_id, startDate, endDate, success, error) {
        this.request({
            type: "GET",
            url: "/monitors/" + monitor_id + "/notifications",
            data: {start_date: startDate, end_date: endDate },
            success: success,
            error: error
        });
    },

    getResults : function(monitor_id, startDate, endDate, success, error) {
        this.request({
            type: "GET",
            url: "/monitors/" + monitor_id + "/results",
            data: {start_date: startDate, end_date: endDate },
            success: success,
            error: error
        });
    },

    getResultsByState : function( monitor_id, state, startDate, endDate, success, error) {
        this.request({
            type: "GET",
            url: "/monitors/" + monitor_id + "/results_by_state/" + state,
            data: {start_date: startDate, end_date: endDate },
            success: success,
            error: error
        });
    }

};
