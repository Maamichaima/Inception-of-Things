# Inception-of-Things
ConfigMap (app1-html)
  └── contient index.html (HTML)
         │
         │ monté via volume
         ▼
Deployment (app-one)
  └── crée des Pods avec label "app: app-one"
  └── nginx sert /usr/share/nginx/html/index.html
         │
         │ sélectionné par label "app: app-one"
         ▼
Service (app-one)
  └── point d'entrée stable vers les pods
         │
         │ ciblé par son nom "app-one"
         ▼
Ingress
  └── si Host: app1.com → envoie vers Service app-one