#!/usr/bin/env node

var AMQP_URL  = process.env.AMQP_URL ? process.env.AMQP_URL : "amqp://localhost:5672";
var QUEUE_NAME = process.env.QUEUE_NAME ? process.env.QUEUE_NAME : 'hyperflow.jobs';
var HYPERFLOW_METRIC_NAME = process.env.HYPERFLOW_METRIC_NAME ? process.env.HYPERFLOW_METRIC_NAME : "QueueLength";
var HYPERFLOW_METRIC_NAMESPACE = process.env.HYPERFLOW_METRIC_NAMESPACE ? process.env.HYPERFLOW_METRIC_NAMESPACE : 'hyperflow';
var CLUSET_NAME = process.env.CLUSET_NAME ? process.env.CLUSET_NAME : 'ecs_test_cluster_hyperflow';

var AWS = require('aws-sdk');
var amqp = require('amqplib/callback_api');

var cloudwatch = new AWS.CloudWatch({region: 'us-east-1'});

amqp.connect(AMQP_URL, function(err, conn) {
  conn.createChannel(function(err, ch) {

    setInterval(function(){
      var mcount=0;

      ch.checkQueue(QUEUE_NAME, function(err, ok) {
        
        //console.log('messageCount:'+ok.messageCount);
        mcount =ok.messageCount;

        var params = {
            MetricData: [ 
              {
                MetricName: HYPERFLOW_METRIC_NAME, 
                Value: mcount,
                Dimensions: [
                  {
                    Name: 'ClusterName', /* required */
                    Value: CLUSET_NAME /* required */
                  }]
              }
            ],
            Namespace: HYPERFLOW_METRIC_NAMESPACE 
            
          };
    
          cloudwatch.putMetricData(params, function(err, data) {
            // if (err) console.log(err, err.stack); 
            // else     console.log(data);           
          });
      });

    }, 1000);

  });
});
