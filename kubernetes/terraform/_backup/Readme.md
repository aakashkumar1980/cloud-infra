<style>
r { color: Red }
o { color: Orange }
g { color: Green }
</style>

# START
1. KubernetesUI
    - Lens
      > Open from the"Favourites" menu. The follow the below steps to open the Grafana and Prometheus Dashboard.
      <br/>
      <br/>
      
      >> Grafana
        - Under "Network" Menu, Go to "Services" section.
        - Click on "*prometheus-grafana*" and it will open a new popup.
        - Then, under "Connection" section, There is a button named "Forward..." in the row named "Ports".
        - Click on this button and give any port of your choice e.g. 9999 and click on "Start". 
        - this will then create a 'Port Forwarding' and the dashboard can be accesses via.
          ```html
          http://localhost:9999 
          ``` 
          NOTE: UserName and Password can be obtained under the "Config" section. Select "Secrets" and click on 'prometheus-grafana' row. Then select admin-user & admin-password by clicking on the 'Show' icon (as it is base64 encoded). 
          <br/>
          <br/>

      >> Prometheus
        - Under "Network" Menu, Go to "Services" section.
        - Click on "*prometheus-kube-prometheus-prometheus*" and it will open a new popup.
        - Then, under "Connection" section, There is a button named "Forward..." in the row named "Ports".
        - Click on this button and give any port of your choice e.g. 9998 and click on "Start". 
        - this will then create a 'Port Forwarding' and the dashboard can be accesses via.
          ```html
          http://localhost:9998 
          ``` 

    - Octant
      
      


<br/>
   

