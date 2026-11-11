# Bitácora · Taller IaC con Terraform · Grupo 1

Arquitectura de Software II · 2026-2

## Integrantes

- Juan Jose Quintero Velasquez
- Nicolas Santiago Carmona
- Brandon Ortiz Medina
- Johan Felipe Molina

Como el profe no nos asignó número de grupo, usamos el **1** (N = 1), así que los nombres quedan `web-g1`, `tf-state-g1`, etc.

## Rotación de roles

| Fase | Operador/a | Navegante | Revisor/a del plan | Bitácora |
|------|------------|-----------|--------------------|----------|
| 0 y 1 | Juan Jose Quintero | Nicolas Carmona | Brandon Ortiz | Johan Molina |
| 2 | Nicolas Carmona | Brandon Ortiz | Johan Molina | Juan Jose Quintero |
| 3 | Brandon Ortiz | Johan Molina | Juan Jose Quintero | Nicolas Carmona |
| 4 | Johan Molina | Juan Jose Quintero | Nicolas Carmona | Brandon Ortiz |
| 5 | Juan Jose Quintero | Nicolas Carmona | Brandon Ortiz | Johan Molina |
| 6 | Nicolas Carmona | Brandon Ortiz | Johan Molina | Juan Jose Quintero |
| 7 | Brandon Ortiz | Johan Molina | Juan Jose Quintero | Nicolas Carmona |
| 8 | Johan Molina | Juan Jose Quintero | Nicolas Carmona | Brandon Ortiz |
| 9 | Juan Jose Quintero | Nicolas Carmona | Brandon Ortiz | Johan Molina |

---

## Fase 0 · Preparación del entorno

### Evidencias

Terraform no estaba instalado, lo instalamos con `winget install Hashicorp.Terraform`.

```text
$ terraform -version
Terraform v1.17.0
on windows_amd64
```

```text
$ docker version
Client:
 Version:           29.6.1
 API version:       1.55
 Go version:        go1.26.4
 Git commit:        8900f1d
 Built:             Fri Jun 26 11:43:32 2026
 OS/Arch:           windows/amd64
 Context:           desktop-linux

Server: Docker Desktop 4.82.0 (233772)
 Engine:
  Version:          29.6.1
  API version:      1.55 (minimum version 1.40)
  Go version:       go1.26.4
  Git commit:       8ec5ab3
  Built:            Fri Jun 26 11:41:04 2026
  OS/Arch:          linux/amd64
  Experimental:     false
 containerd:
  Version:          v2.2.5
 runc:
  Version:          1.3.6
 docker-init:
  Version:          0.19.0
```

```text
$ git --version
git version 2.56.0.windows.2
```

Imágenes descargadas: `nginx:1.27-alpine`, `nginx:1.28-alpine` y `postgres:17-alpine`.

Nota: Docker Desktop no arrancaba al principio, se cerraba con un error del "Inference manager" porque había un socket viejo trabado en `%LOCALAPPDATA%\Docker\run\dockerInference`. Lo solucionamos cerrando Docker, renombrando esa carpeta `run` a `run.old` y volviendo a abrirlo (Docker la crea de nuevo).

### Respuestas

Esta fase no tiene preguntas.

---

## Fase 1 · Arranque: hacerlo a mano

### Evidencias

```text
$ docker run -d --name clickops-g1 -p 8090:80 nginx:1.27-alpine
bde43969d69aadd9024d6444b5b4af737d30d987310d856723f2c2b82db3a94d

$ curl -s http://localhost:8090 | head -5
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
```

Segundo intento con el mismo comando:

```text
$ docker run -d --name clickops-g1 -p 8090:80 nginx:1.27-alpine
docker: Error response from daemon: Conflict. The container name "/clickops-g1" is already in use by container "bde43969d69aadd9024d6444b5b4af737d30d987310d856723f2c2b82db3a94d". You have to remove (or rename) that container to be able to reuse that name.
```

Con otro nombre y el mismo puerto:

```text
$ docker run -d --name clickops-g1-2 -p 8090:80 nginx:1.27-alpine
d30e027de2eda65713f33261aec3c82dea0c043e133f06a8e8448e837dceaf76
docker: Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint clickops-g1-2 (...): Bind for 0.0.0.0:8090 failed: port is already allocated
```

Ojo que en este caso Docker sí alcanzó a crear el contenedor `clickops-g1-2` (devolvió el id), pero quedó sin arrancar porque el puerto ya estaba ocupado. O sea, quedó basura a medias.

Limpieza:

```text
$ docker rm -f clickops-g1 clickops-g1-2
clickops-g1
clickops-g1-2

$ docker ps -a --filter name=clickops
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

**El mismo objetivo de dos formas**

Imperativa (pasos en orden):

1. Descargar la imagen `nginx:1.27-alpine`.
2. Crear un contenedor llamado `clickops-g1` con esa imagen.
3. Publicar el puerto 80 del contenedor en el 8090 del equipo.
4. Arrancar el contenedor en segundo plano.

Declarativa (resultado deseado):

> Debe existir un único servidor nginx 1.27 llamado `clickops-g1` respondiendo en http://localhost:8090.

### Respuestas

**1. ¿Qué error produjo el segundo `docker run`? ¿Qué dice eso sobre la idempotencia de un comando imperativo?**

Dio `Conflict. The container name "/clickops-g1" is already in use`. El comando no revisa si lo que queremos ya existe, simplemente intenta crear otra vez. Entonces no es idempotente: correrlo dos veces no da el mismo resultado, la segunda vez falla, y si le cambiamos el nombre intenta crear un segundo servidor (que también falló, pero por el puerto, y además dejó un contenedor creado a medias).

**2. Si otro grupo necesitara mañana un servidor idéntico, ¿qué tendrían que contarle y dónde quedó registrado lo que hicieron?**

Tendríamos que explicarle todo de memoria: la imagen y su versión exacta, el nombre, el puerto, que va con `-d`, y además que tenga cuidado con nombres y puertos repetidos. Lo que hicimos solo quedó en el historial de la terminal de quien tecleó, que no se versiona, no se comparte y se puede perder. No hay ningún archivo que lo describa.

**3. ¿Cuáles de los cuatro puntos de la diapositiva «Por qué duele» vivieron en esta fase?**

Prácticamente los cuatro. *Propenso a errores humanos*: nos tropezamos con el nombre repetido y el puerto ocupado. *Imposible de reproducir igual dos veces*: repetir el mismo comando no dio lo mismo. *Sin historial*: no queda registro de quién hizo qué, solo la terminal. *El conocimiento se va con la persona*: el único que sabe cómo quedó el servidor es el que lo tecleó.

---

## Fase 2 · Primer despliegue: write → init → plan → apply

### Evidencias

Creamos `infra/main.tf` con el código de la guía (grupo 1, contenedor `web-g1` en el 8080).

```text
$ terraform init
Initializing the backend...

Initializing provider plugins...
- Finding kreuzwerker/docker versions matching "~> 4.6"...
- Installing kreuzwerker/docker v4.6.0...
- Installed kreuzwerker/docker v4.6.0 (self-signed, key ID 0DCE698927DAF8EC)
...
Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above.
...
Terraform has been successfully initialized!

$ ls -a
.  ..  .terraform  .terraform.lock.hcl  main.tf
```

```text
$ terraform fmt
$ terraform validate
Success! The configuration is valid.
```

```text
$ terraform plan
  # docker_container.web will be created
  + resource "docker_container" "web" {
      + name     = "web-g1"
      + must_run = true
      + image    = (known after apply)
      ...
      + ports {
          + external = 8080
          + internal = 80
          + ip       = "0.0.0.0"
          + protocol = "tcp"
        }
    }

  # docker_image.nginx will be created
  + resource "docker_image" "nginx" {
      + id           = (known after apply)
      + image_id     = (known after apply)
      + keep_locally = true
      + name         = "nginx:1.27-alpine"
    }

Plan: 2 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + url = "http://localhost:8080"
```

Revisor (Johan): «Aprobado: 2 a crear, 0 a cambiar, 0 a destruir».

```text
$ terraform apply
docker_image.nginx: Creating...
docker_image.nginx: Creation complete after 1s [id=sha256:65645c7bb6a0...nginx:1.27-alpine]
docker_container.web: Creating...
docker_container.web: Creation complete after 1s [id=50d71ba57ebd...]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

url = "http://localhost:8080"
```

```text
$ curl -s localhost:8080 | grep -i title
<title>Welcome to nginx!</title>

$ terraform output
url = "http://localhost:8080"

$ docker ps --filter name=web-g1
CONTAINER ID   IMAGE          COMMAND                  CREATED        STATUS                  PORTS                  NAMES
50d71ba57ebd   65645c7bb6a0   "/docker-entrypoint.…"   1 second ago   Up Less than a second   0.0.0.0:8080->80/tcp   web-g1
```

Captura de la página: [evidencias/fase2-web-8080.png](evidencias/fase2-web-8080.png)

`git status` antes del commit (no aparecen `.terraform/` ni `terraform.tfstate` porque el `.gitignore` los saca):

```text
?? evidencias/fase2-web-8080.png
?? infra/.terraform.lock.hcl
?? infra/main.tf
```

### Respuestas

**1. Pidieron un solo servidor. ¿Cuántos recursos creó el plan y por qué?**

Creó 2: `docker_image.nginx` y `docker_container.web`. Para Terraform la imagen también es un recurso que tiene que existir (y que él controla), no solo un dato del contenedor. Por eso aunque nosotros pensemos en "un servidor", en el código hay dos cosas declaradas.

**2. El contenedor usa `docker_image.nginx.image_id`. ¿Qué orden de creación impone esa referencia?**

Esa referencia crea una dependencia implícita: primero tiene que existir la imagen y después el contenedor, porque el contenedor necesita el `image_id` que solo se conoce cuando la imagen ya está. Se ve en la salida del apply: `docker_image.nginx: Creating...` termina y recién ahí arranca `docker_container.web`. Es justo lo de la diapositiva «Qué ocurre cuando aplicas»: Terraform lee el código, calcula el plan (con este orden de dependencias), llama al provider de Docker y Docker le responde con los datos (como el id de la imagen) que usa el siguiente recurso.

**3. ¿Qué descargó `terraform init`, dónde lo guardó y para qué sirve `.terraform.lock.hcl`?**

Descargó el provider `kreuzwerker/docker` versión 4.6.0, que es el plugin que sabe hablar con la API de Docker. Lo guardó dentro de `infra/.terraform/providers/`. El `.terraform.lock.hcl` deja anotada la versión exacta y los hashes del provider, para que cualquiera del equipo que haga `init` use exactamente la misma versión y no una distinta que pueda comportarse diferente. Por eso ese archivo sí va a Git y la carpeta `.terraform/` no.

**4. De los cuatro bloques de la diapositiva «Cómo se escribe Terraform», ¿cuál no aparece todavía en su archivo?**

El bloque `variable`. Ya tenemos `provider`, `resource` y `output`, pero todo está quemado en el código (nombre, puerto, imagen).

**5. Comparen con la Fase 1: ¿dónde quedó registrado ahora lo que hicieron?**

En `infra/main.tf`, que está versionado en Git con su commit. Cualquiera puede leer qué servidor existe, con qué imagen y puerto, y recrearlo igualito con `terraform apply`. Además Terraform guarda en `terraform.tfstate` lo que creó realmente (ese archivo es local y no va al repo).

---

## Fase 3 · Idempotencia y estado

### Evidencias

**Paso 1.** Apply otra vez sin tocar nada:

```text
$ terraform apply
docker_image.nginx: Refreshing state... [id=sha256:65645c7bb6a0...nginx:1.27-alpine]
docker_container.web: Refreshing state... [id=50d71ba57ebd...]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
```

**Paso 2.** Consultar el state:

```text
$ terraform state list
docker_container.web
docker_image.nginx

$ terraform state show docker_container.web
# docker_container.web:
resource "docker_container" "web" {
    command      = ["nginx", "-g", "daemon off;"]
    entrypoint   = ["/docker-entrypoint.sh"]
    hostname     = "50d71ba57ebd"
    id           = "50d71ba57ebde377da07f3ff2d313f0a4d42928944ab1fb67013f2727c59c700"
    image        = "sha256:65645c7bb6a0661892a8b03b89d0743208a18dd2f3f17a54ef4b76fb8e2f2a10"
    ipc_mode     = "private"
    log_driver   = "json-file"
    must_run     = true
    name         = "web-g1"
    network_data = [
        {
            gateway      = "172.17.0.1"
            ip_address   = "172.17.0.2"
            mac_address  = "1e:f8:8a:3c:7f:7a"
            network_name = "bridge"
            ...
        },
    ]
    network_mode = "bridge"
    runtime      = "runc"
    shm_size     = 64
    stop_signal  = "SIGQUIT"
    ...
    ports {
        external = 8080
        internal = 80
        ip       = "0.0.0.0"
        protocol = "tcp"
    }
}
```

**Paso 3.** Abrimos `terraform.tfstate` solo para leer:

```text
"version": 4
"terraform_version": "1.17.0"
"serial": 4
"lineage": "627633b4-e632-0728-dfa5-f6a6a2fa2830"
"resources": [ docker_container.web, docker_image.nginx ]
```

Valor de `serial` antes del cambio: **4**.

**Paso 4.** Cambiamos `nginx:1.27-alpine` por `nginx:1.28-alpine` y planeamos:

```text
$ terraform plan
  # docker_container.web must be replaced
-/+ resource "docker_container" "web" {
      ~ id    = "50d71ba57ebd..." -> (known after apply)
      ~ image = "sha256:65645c7bb6a0..." -> (known after apply) # forces replacement
        ...
    }

  # docker_image.nginx must be replaced
-/+ resource "docker_image" "nginx" {
      ~ image_id = "sha256:65645c7bb6a0..." -> (known after apply)
      ~ name     = "nginx:1.27-alpine" -> "nginx:1.28-alpine" # forces replacement
        ...
    }

Plan: 2 to add, 0 to change, 2 to destroy.
```

Revisor (Juan Jose): «Veo `-/+` en los dos recursos y `forces replacement` en `name` de la imagen y en `image` del contenedor. Aprobado: 2 a crear, 0 a cambiar, 2 a destruir».

```text
$ terraform apply
docker_container.web: Destroying... [id=50d71ba57ebd...]
docker_container.web: Destruction complete after 1s
docker_image.nginx: Destroying... [id=sha256:65645c7bb6a0...nginx:1.27-alpine]
docker_image.nginx: Destruction complete after 0s
docker_image.nginx: Creating...
docker_image.nginx: Creation complete after 0s [id=sha256:a8b39bd9cf0f...nginx:1.28-alpine]
docker_container.web: Creating...
docker_container.web: Creation complete after 1s [id=154c325ea4e4...]

Apply complete! Resources: 2 added, 0 changed, 2 destroyed.
```

**Paso 5.** Todo estable:

```text
$ terraform plan
No changes. Your infrastructure matches the configuration.

$ docker ps --filter name=web-g1 --format '{{.Names}} {{.Image}} {{.Status}}'
web-g1 a8b39bd9cf0f Up 1 second
```

`serial` después del apply: **9**. El `lineage` sigue igual.

### Respuestas

**1. ¿Qué respondió Terraform en el paso 1 y en qué se diferencia del segundo `docker run` de la Fase 1?**

Respondió `No changes. Your infrastructure matches the configuration` y `0 added, 0 changed, 0 destroyed`. El `docker run` repetido intentó crear otra vez y reventó con conflicto de nombre. Terraform primero compara lo que pedimos con lo que ya existe y, como ya está igual, no hace nada. Eso es la idempotencia: aplicar lo mismo varias veces deja el mismo resultado, como el botón del ascensor.

**2. ¿Qué datos guarda el state que no escribieron en `main.tf`? ¿Para qué los necesita Terraform?**

Guarda el `id` real del contenedor y de la imagen, el hash `sha256` de la imagen, la IP, el gateway y la MAC de la red, el hostname, el comando y entrypoint, el runtime, etc. Además el `serial`, el `lineage` y la versión de Terraform. Lo necesita para saber qué objeto real corresponde a cada recurso del código (sin el id no sabría cuál contenedor es "el suyo"), para calcular las diferencias en el plan y para saber qué tiene que borrar o reemplazar.

**3. ¿Por qué el cambio de imagen reemplazó el contenedor en lugar de modificarlo?**

Porque un contenedor de Docker no puede cambiar su imagen después de creado, así que el atributo `image` está marcado como `forces replacement`. Terraform destruye el viejo y crea uno nuevo (`-/+`). Es la idea de infraestructura inmutable: no entramos a "curar" el servidor actualizando cosas adentro, lo cambiamos por uno nuevo y limpio que sale del código. Así todos los servidores son reproducibles y no acumulan cambios raros.

**4. ¿Cómo cambió `serial` después del `apply` y qué creen que representa?**

Pasó de 4 a 9. Es un contador de versión del state: cada vez que Terraform escribe el archivo (aquí escribió varias veces, al destruir y crear cada recurso) le suma uno. Junto con el `lineage`, que identifica "la familia" del state y no cambia, sirve para no pisar un state nuevo con una copia más vieja.

**5. En un proyecto real con bases de datos, ¿qué riesgo habría si este archivo se subiera a Git?**

El state guarda en texto plano todos los atributos de los recursos, y en una base de datos eso incluye usuario, contraseña, cadenas de conexión, IPs internas, etc. Si va a Git esos secretos quedan en el historial para siempre aunque luego se borre el archivo. Además, si cada uno trabaja con su copia del state desde Git, se desincronizan y Terraform podría intentar crear duplicados o borrar cosas que sí existen.

---

## Fase 4 · Drift: cuando la realidad se desvía

En esta fase sí tocamos Docker a mano a propósito, porque la guía lo pide.

### Evidencias

**Experimento A · Apagar el servidor**

```text
$ docker stop web-g1
web-g1

$ terraform plan
docker_image.nginx: Refreshing state... [id=sha256:a8b39bd9cf0f...nginx:1.28-alpine]
docker_container.web: Refreshing state... [id=154c325ea4e4...]

  # docker_container.web must be replaced
-/+ resource "docker_container" "web" {
      ~ must_run          = false -> true
      - publish_all_ports = false -> null
      + ports { # forces replacement
          + external = 8080 # forces replacement
          + internal = 80 # forces replacement
          + ip       = "0.0.0.0" # forces replacement
          + protocol = "tcp" # forces replacement
        }
    }

Plan: 1 to add, 0 to change, 1 to destroy.
```

Revisor (Nicolas): «El contenedor detenido ya no reporta los puertos, por eso pide reemplazo. Aprobado: 1 a crear, 0 a cambiar, 1 a destruir».

```text
$ terraform apply
docker_container.web: Destroying... [id=154c325ea4e4...]
docker_container.web: Destruction complete after 0s
docker_container.web: Creating...
docker_container.web: Creation complete after 0s [id=f58b41ab74f7...]
Apply complete! Resources: 1 added, 0 changed, 1 destroyed.

$ curl -s localhost:8080 | grep title
<title>Welcome to nginx!</title>
```

**Experimento B · Borrar el servidor**

```text
$ docker rm -f web-g1
web-g1

$ terraform plan -refresh-only
Note: Objects have changed outside of Terraform

Terraform detected the following changes made outside of Terraform since the
last "terraform apply" which may have affected this plan:

  # docker_container.web has been deleted
  - resource "docker_container" "web" {
    }

This is a refresh-only plan, so Terraform will not take any actions to undo
these.

$ terraform plan
  # docker_container.web will be created
Plan: 1 to add, 0 to change, 0 to destroy.
```

La primera salida solo cuenta lo que pasó por fuera ("has been deleted") y no propone nada; la segunda ya propone volver al estado deseado creando el contenedor.

Revisor (Nicolas): «Aprobado: 1 a crear, 0 a cambiar, 0 a destruir».

```text
$ terraform apply
docker_container.web: Creating...
docker_container.web: Creation complete after 1s [id=89d8a9378d31...]
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

$ curl -s localhost:8080 | grep title
<title>Welcome to nginx!</title>
```

**Experimento C · Cambiar el contenido por dentro**

```text
$ docker exec web-g1 sh -c "echo '<h1>Cambio manual</h1>' > /usr/share/nginx/html/index.html"
$ curl -s localhost:8080
<h1>Cambio manual</h1>

$ terraform plan
No changes. Your infrastructure matches the configuration.
```

Captura de la página con el cambio manual: [evidencias/fase4-cambio-manual.png](evidencias/fase4-cambio-manual.png)

Terraform no ve nada. Lo corregimos reemplazando el contenedor completo:

```text
$ terraform apply -replace=docker_container.web
  # docker_container.web will be replaced, as requested
-/+ resource "docker_container" "web" {
    ...
Plan: 1 to add, 0 to change, 1 to destroy.
```

Revisor (Nicolas): «Reemplazo pedido por nosotros. Aprobado: 1 a crear, 0 a cambiar, 1 a destruir».

```text
docker_container.web: Destroying... [id=89d8a9378d31...]
docker_container.web: Destruction complete after 1s
docker_container.web: Creating...
docker_container.web: Creation complete after 0s [id=0abb0b0d2545...]
Apply complete! Resources: 1 added, 0 changed, 1 destroyed.

$ curl -s localhost:8080 | grep title
<title>Welcome to nginx!</title>

$ terraform plan
No changes. Your infrastructure matches the configuration.
```

**Tabla de drift**

| Experimento | ¿El plan lo detectó? | ¿Qué propuso Terraform? | ¿Cómo quedó corregido? |
|---|---|---|---|
| A · Apagar | Sí. `must_run` pasó de `false` a `true` y los puertos ya no aparecían | Reemplazar el contenedor (`-/+`, 1 a crear y 1 a destruir) | Con `terraform apply` se recreó y la página volvió a responder |
| B · Borrar | Sí. `-refresh-only` mostró `has been deleted` | Crear el contenedor de nuevo (1 a crear) | Con `terraform apply` se creó otra vez y la página volvió |
| C · Cambiar por dentro | No. El plan dijo `No changes` | Nada | Lo forzamos con `terraform apply -replace=docker_container.web`, que creó un contenedor limpio con la página original |

### Respuestas

**1. ¿Por qué Terraform no detectó el experimento C? ¿Qué tipo de herramienta se encarga de ese nivel?**

Porque Terraform solo compara los atributos del recurso que conoce el provider (imagen, nombre, puertos, si está corriendo...), no lo que hay dentro del sistema de archivos del contenedor. El contenedor seguía existiendo con la misma imagen y los mismos puertos, entonces para él todo estaba bien. Terraform es de aprovisionamiento ("que exista la máquina"); lo de adentro, archivos y software instalado, es trabajo de las herramientas de gestión de configuración como Ansible, Chef o Puppet.

**2. ¿Por qué `-replace` es una corrección coherente con la infraestructura inmutable?**

Porque en vez de meternos al contenedor a arreglar el `index.html` a mano (que sería tratarlo como mascota), lo botamos y creamos uno nuevo desde la imagen y el código. Así volvemos a un estado conocido y reproducible, sin cambios escondidos que nadie documentó.

**3. En un equipo real, ¿cómo detectarían el drift sin esperar a que alguien ejecute `plan` por casualidad?**

Programando un `terraform plan` automático, por ejemplo cada noche en el pipeline de CI/CD, con `-detailed-exitcode` (devuelve código 2 cuando hay diferencias) o con `plan -refresh-only`, y que si encuentra cambios mande una alerta al equipo (correo, Slack, un issue). También hay plataformas como Terraform Cloud que traen detección de drift. Y de paso, quitar permisos para que nadie pueda tocar la infraestructura a mano.

---

## Fase 5 · Las piezas que dan flexibilidad

### Evidencias

Separamos el código en `main.tf`, `variables.tf`, `locals.tf`, `data.tf`, `outputs.tf` y `terraform.tfvars`, y resolvimos los TODO:

- TODO 1: variable `mensaje` (string, sin default) en `variables.tf`.
- TODO 2: local `etiquetas` con `curso = "arquitectura-sw-2"` y `grupo = tostring(var.grupo)`.
- TODO 3: bloque `dynamic "labels"` en el contenedor que recorre `local.etiquetas`.
- TODO 4 y 5: outputs `contenedor` (`docker_container.web.name`) y `red_driver` (`data.docker_network.bridge.driver`).

```text
$ terraform validate
Success! The configuration is valid.

$ terraform plan
data.docker_network.bridge: Reading...
data.docker_network.bridge: Read complete after 0s [id=bed7a41e60b0...]

  # docker_container.web must be replaced
-/+ resource "docker_container" "web" {
      + labels { # forces replacement
          + label = "curso"
          + value = "arquitectura-sw-2"
        }
      + labels { # forces replacement
          + label = "grupo"
          + value = "1"
        }
      + upload { # forces replacement
          + content = <<-EOT
                <h1>Hola desde el grupo 1</h1>
                <p>Desplegado con Terraform por el grupo 1</p>
            EOT
          + file    = "/usr/share/nginx/html/index.html"
        }
        ...
    }

Plan: 1 to add, 0 to change, 1 to destroy.

Changes to Outputs:
  + contenedor = "web-g1"
  + red_driver = "bridge"
```

Revisor (Brandon): «El contenedor se reemplaza porque ahora le metemos un archivo con `upload` y le ponemos etiquetas, y esas dos cosas Docker solo las acepta al crear el contenedor (`forces replacement`). La imagen no cambia porque ya era la 1.28. Aprobado: 1 a crear, 0 a cambiar, 1 a destruir».

```text
$ terraform apply
docker_container.web: Destroying... [id=0abb0b0d2545...]
docker_container.web: Destruction complete after 0s
docker_container.web: Creating...
docker_container.web: Creation complete after 1s [id=63703c67755a...]

Apply complete! Resources: 1 added, 0 changed, 1 destroyed.

Outputs:

contenedor = "web-g1"
red_driver = "bridge"
url = "http://localhost:8080"

$ curl -s localhost:8080
<h1>Hola desde el grupo 1</h1>
<p>Desplegado con Terraform por el grupo 1</p>

$ docker inspect web-g1 --format '{{json .Config.Labels}}'
{"curso":"arquitectura-sw-2","grupo":"1","maintainer":"NGINX Docker Maintainers <docker-maint@nginx.com>"}
```

Captura: [evidencias/fase5-mensaje-grupo.png](evidencias/fase5-mensaje-grupo.png)

Consola:

```text
$ terraform console
> local.nombre
"web-g1"
> upper(var.mensaje)
"HOLA DESDE EL GRUPO 1"
> format("web-g%02d", var.grupo)
"web-g01"
> local.etiquetas
{
  "curso" = "arquitectura-sw-2"
  "grupo" = "1"
}
> data.docker_network.bridge.driver
"bridge"
> exit
```

Prueba de la validación (solo plan):

```text
$ terraform plan -var="puerto=9500"
Error: Invalid value for variable

  on variables.tf line 6:
   6: variable "puerto" {
    ├────────────────
    │ var.puerto is 9500

El puerto debe estar entre 8000 y 8999.

This was checked by the validation rule at variables.tf:11,3-13.

$ terraform plan -var="puerto=8085"
          ~ external = 8080 -> 8085 # forces replacement
Plan: 1 to add, 0 to change, 1 to destroy.
  ~ url        = "http://localhost:8080" -> "http://localhost:8085"
```

Este último no lo aplicamos, solo era para ver que pasaba la validación.

### Respuestas

**1. `puerto` tiene un default, puede venir de `terraform.tfvars` y se pasó con `-var`. ¿Qué valor gana cuando hay varios?**

Gana el `-var` de la línea de comandos. El orden de menor a mayor prioridad es: el `default` de la variable, después `terraform.tfvars`, después los `*.auto.tfvars`, y al final `-var` / `-var-file` (si hay varios, el último que se escriba). Se vio con `-var="puerto=8085"`: el plan quería cambiar de 8080 a 8085 aunque el default sea 8080.

**2. ¿Qué hizo el bloque `validation` con el puerto 9500? ¿En qué se parece a la idea de Policy as Code?**

Frenó el plan de una vez con nuestro mensaje ("El puerto debe estar entre 8000 y 8999") sin siquiera llegar a hablar con Docker. Se parece a Policy as Code porque es una regla escrita en código que se revisa sola antes de aplicar y bloquea una configuración que no está permitida, sin depender de que alguien se acuerde de revisarla.

**3. ¿Terraform creó la red `bridge`? ¿Qué le pasará cuando el grupo ejecute `destroy`?**

No, la red ya existía en Docker. El bloque `data` solo la lee (de ahí sacamos el `driver`), no la crea ni la administra. Por eso con `destroy` no le pasa nada: Terraform solo destruye los recursos que él maneja (`resource`), no los data sources.

**4. ¿Qué ganan con `local.nombre` frente a escribir `"web-gN"` en cada lugar donde se necesita?**

Que el nombre se arma en un solo sitio a partir de `var.grupo`. Si cambia el grupo o el formato del nombre, se toca una línea y se actualiza en todos lados, sin riesgo de que quede un `web-g1` olvidado o mal escrito en alguna parte. Además el mismo código sirve para cualquier grupo con solo cambiar el `tfvars`.

---

## Fase 6 · Módulos: la receta una sola vez

### Evidencias

Creamos `infra/modules/sitio_web/` con `versions.tf`, `variables.tf` (con la validación del puerto que antes estaba en la raíz), `main.tf` y `outputs.tf` (`url` y `nombre`). En la raíz quitamos `docker_image.nginx` y `docker_container.web` y llamamos el módulo tres veces: `tienda` (8081), `blog` (8082) y `docs` (8083). También limpiamos `local.nombre`, `local.html`, las variables `puerto` y `mensaje` (y `mensaje` del `tfvars`) y los outputs `url` y `contenedor`. Agregamos el output `urls` con las tres direcciones.

Antes del `init`, el plan falla:

```text
$ terraform plan
Error: Module not installed
Error: Module not installed
Error: Module not installed
```

```text
$ terraform init
Initializing modules...
- tienda in modules\sitio_web
- docs in modules\sitio_web
- blog in modules\sitio_web
- Reusing version 4.6.0 of kreuzwerker/docker from the dependency lock file
- Using previously-installed kreuzwerker/docker v4.6.0
Terraform has been successfully initialized!

$ terraform validate
Success! The configuration is valid.
```

```text
$ terraform plan
  # docker_container.web will be destroyed
  # (because docker_container.web is not in configuration)
  # docker_image.nginx will be destroyed
  # (because docker_image.nginx is not in configuration)
  # module.blog.docker_container.this will be created
  # module.blog.docker_image.this will be created
  # module.docs.docker_container.this will be created
  # module.docs.docker_image.this will be created
  # module.tienda.docker_container.this will be created
  # module.tienda.docker_image.this will be created

Plan: 6 to add, 0 to change, 2 to destroy.

Changes to Outputs:
  - contenedor = "web-g1" -> null
  - url        = "http://localhost:8080" -> null
  + urls       = [
      + "http://localhost:8081",
      + "http://localhost:8082",
      + "http://localhost:8083",
    ]
```

Revisor (Johan): «Se destruyen `web-g1` y su imagen porque ya no están en el código raíz (ahora todo sale del módulo y las direcciones de los recursos cambian). Se crean 3 imágenes y 3 contenedores, uno por cada llamada al módulo. La imagen tiene `keep_locally = true`, así que al destruirla no se borra de Docker. Aprobado: 6 a crear, 0 a cambiar, 2 a destruir».

```text
$ terraform apply
module.blog.docker_image.this: Creating...
module.docs.docker_image.this: Creating...
module.tienda.docker_image.this: Creating...
docker_container.web: Destroying... [id=63703c67755a...]
docker_container.web: Destruction complete after 1s
docker_image.nginx: Destroying... [id=sha256:a8b39bd9cf0f...nginx:1.28-alpine]
docker_image.nginx: Destruction complete after 0s
module.docs.docker_image.this: Creation complete after 1s
module.tienda.docker_image.this: Creation complete after 1s
module.blog.docker_image.this: Creation complete after 1s
module.tienda.docker_container.this: Creating...
module.docs.docker_container.this: Creating...
module.blog.docker_container.this: Creating...
module.docs.docker_container.this: Creation complete after 1s [id=ebb36a8d4a0a...]
module.tienda.docker_container.this: Creation complete after 1s [id=f0b27202ed40...]
module.blog.docker_container.this: Creation complete after 1s [id=ace0048d4616...]

Apply complete! Resources: 6 added, 0 changed, 2 destroyed.

Outputs:

red_driver = "bridge"
urls = [
  "http://localhost:8081",
  "http://localhost:8082",
  "http://localhost:8083",
]
```

```text
$ for p in 8081 8082 8083; do echo "$p: $(curl -s localhost:$p | head -1)"; done
8081: <h1>Tienda del grupo 1</h1>
8082: <h1>Blog del grupo 1</h1>
8083: <h1>Docs del grupo 1</h1>

$ terraform output urls
[
  "http://localhost:8081",
  "http://localhost:8082",
  "http://localhost:8083",
]
```

Capturas: [tienda](evidencias/fase6-tienda-8081.png), [blog](evidencias/fase6-blog-8082.png), [docs](evidencias/fase6-docs-8083.png)

El reto opcional del `for_each` con bloques `moved` no lo hicimos aquí porque en la Fase 7 igual se pasa a un solo `module "sitio"` con `for_each`.

### Respuestas

**1. Anoten la línea `Plan:` del paso 8. ¿Qué se destruyó, qué se creó y por qué?**

`Plan: 6 to add, 0 to change, 2 to destroy.` Se destruyeron `docker_container.web` (web-g1) y `docker_image.nginx` porque ya no están declarados en la raíz; para Terraform un recurso dentro de un módulo tiene otra dirección (`module.tienda.docker_container.this`), así que lo ve como algo distinto y no como un "movimiento". Se crearon 6 recursos: una imagen y un contenedor por cada uno de los tres usos del módulo (tienda, blog y docs).

**2. ¿Qué error obtendrían si el módulo no tuviera `versions.tf`?**

Lo probamos en una copia aparte y `terraform init` falla con:

```text
Error: Failed to query available provider packages

Could not retrieve the list of available versions for provider
hashicorp/docker: provider registry registry.terraform.io does not have a
provider named registry.terraform.io/hashicorp/docker

Did you intend to use kreuzwerker/docker? If so, you must specify that source
address in each module which requires that provider.
```

Pasa porque cada módulo resuelve sus providers por su cuenta, y si no le decimos el origen asume `hashicorp/docker`, que no existe.

**3. Si mañana hay que agregar una etiqueta a todos los sitios, ¿cuántos archivos tocan con módulo? ¿Cuántos bloques habrían tocado copiando y pegando?**

Con el módulo tocamos un solo archivo (`modules/sitio_web/main.tf`, un bloque `labels` en el contenedor) y se aplica a los tres sitios. Copiando y pegando tendríamos que tocar tres bloques `docker_container` (uno por sitio), y con el riesgo de que alguno quede distinto o se nos olvide.

**4. ¿Qué necesitaría otro grupo para usar su módulo sin copiar la carpeta?**

Que publiquemos el módulo en un lugar accesible, por ejemplo nuestro repo de GitHub, y ellos lo referencien en el `source`, algo como `source = "git::https://github.com/<usuario>/iac-taller-g1.git//infra/modules/sitio_web?ref=v1.0"` (mejor con un tag para fijar la versión), o subirlo a un registry. Ellos solo tendrían que pasar las variables `nombre`, `puerto`, `mensaje` (e `imagen` si quieren otra) y tener Docker y el provider `kreuzwerker/docker`.

---

## Fase 7 · State remoto y varios ambientes

La contraseña del backend no aparece en ningún archivo del repo. En esta bitácora la reemplazamos por `****`.

### Evidencias

**Parte A · State remoto con bloqueo**

Backend (lo corrimos en una sola línea porque estábamos en Windows):

```text
$ docker run -d --name tf-state-g1 -e POSTGRES_USER=terraform -e POSTGRES_PASSWORD=**** -e POSTGRES_DB=terraform_backend -p 5433:5432 postgres:17-alpine
3143e63916f1969c6111910fc903ffed219539468a79b2e1ef73965dee340edf

$ docker exec tf-state-g1 pg_isready -U terraform
/var/run/postgresql:5432 - accepting connections
```

Conexión solo en la terminal:

```text
$ export PG_CONN_STR="postgres://terraform:****@localhost:5433/terraform_backend?sslmode=disable"
```

Agregamos `backend "pg" {}` vacío dentro del bloque `terraform` de `main.tf` y migramos:

```text
$ terraform init -migrate-state
Initializing the backend...
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "local" backend to the
  newly configured "pg" backend. No existing state was found in the newly
  configured "pg" backend. Do you want to copy this state to the new "pg"
  backend? Enter "yes" to copy and "no" to start with an empty state.

  Enter a value: yes

Successfully configured the backend "pg"! Terraform will automatically
use this backend unless the backend configuration changes.
...
Terraform has been successfully initialized!

$ terraform state list
data.docker_network.bridge
module.blog.docker_container.this
module.blog.docker_image.this
module.docs.docker_container.this
module.docs.docker_image.this
module.tienda.docker_container.this
module.tienda.docker_image.this

$ docker exec tf-state-g1 psql -U terraform -d terraform_backend -c "SELECT id, name FROM terraform_remote_state.states;"
 id |  name
----+---------
  1 | default
(1 row)
```

Prueba de bloqueo. En la terminal 1 corrimos `terraform apply` y lo dejamos esperando en el `Enter a value:`. La primera vez no sirvió porque no había cambios y el apply terminó solo sin preguntar nada, así que la repetimos con `terraform apply -var="imagen=nginx:1.27-alpine"` para que sí tuviera algo que confirmar (respondimos `no`, no se aplicó nada). Mientras tanto, en la terminal 2:

```text
$ terraform plan

Error: Error acquiring the state lock

Error message: Workspace is already locked: default
Lock Info:
  ID:        e4e66ddc-ff97-9fa7-5d75-5d5764e32daf
  Path:
  Operation: OperationTypePlan
  Who:       PC\juanj@PC
  Version:   1.17.0
  Created:   2026-11-09 21:59:06.402187 +0000 UTC
  Info:

Terraform acquires a state lock to protect the state from being written
by multiple users at the same time. Please resolve the issue above and try
again. For most commands, you can disable locking with the "-lock=false"
flag, but this is not recommended.
```

Terminal 1:

```text
Plan: 6 to add, 0 to change, 6 to destroy.
  Enter a value: no

Apply cancelled.
```

**Parte B · Un mismo código, tres ambientes**

Destroy del workspace `default`:

```text
$ terraform destroy
  # module.blog.docker_container.this will be destroyed
  # module.blog.docker_image.this will be destroyed
  # module.docs.docker_container.this will be destroyed
  # module.docs.docker_image.this will be destroyed
  # module.tienda.docker_container.this will be destroyed
  # module.tienda.docker_image.this will be destroyed

Plan: 0 to add, 0 to change, 6 to destroy.
```

Revisor (Juan Jose): «Estamos en `default`, se van los 3 sitios y sus imágenes (las imágenes quedan en Docker por el `keep_locally`). Aprobado: 0 a crear, 0 a cambiar, 6 a destruir».

```text
Destroy complete! Resources: 6 destroyed.

$ docker ps --format '{{.Names}}'
tf-state-g1
```

Cambios en el código:

- `locals.tf`: los ambientes de la guía con el TODO 1 resuelto (`imagen` por ambiente: dev y staging con `nginx:1.28-alpine`, prod con `nginx:1.27-alpine`).
- `main.tf`: un solo `module "sitio"` con `for_each = local.sitios` y `imagen = local.amb.imagen` (TODO 2).
- `outputs.tf`: `urls` ahora es un map `nombre => url` recorriendo `module.sitio` (TODO 3).
- `variables.tf`: quitamos la variable `imagen` porque con el TODO 2 ya nadie la usaba (la imagen ahora sale del ambiente). Fue lo único que hicimos por fuera de la guía, para no dejar una variable muerta.

Plan antes de `init` y en `default`:

```text
$ terraform plan
Error: Module not installed

$ terraform init
Initializing modules...
- sitio in modules\sitio_web
Terraform has been successfully initialized!

$ terraform plan
Error: Invalid index

  on locals.tf line 10, in locals:
  10:   amb = local.ambientes[local.entorno]
    ├────────────────
    │ local.ambientes is object with 3 attributes
    │ local.entorno is "default"

The given key does not identify an element in this collection value.
```

Despliegue por ambiente:

```text
$ terraform workspace new dev
Created and switched to workspace "dev"!

$ terraform apply
  # module.sitio["tienda"].docker_container.this will be created
  # module.sitio["tienda"].docker_image.this will be created
Plan: 2 to add, 0 to change, 0 to destroy.
```

Revisor (Juan Jose): «Workspace `dev`, 1 sitio (tienda). Aprobado: 2 a crear, 0 a cambiar, 0 a destruir».

```text
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

urls = {
  "tienda-g1-dev" = "http://localhost:8101"
}
```

```text
$ terraform workspace new staging
Created and switched to workspace "staging"!

$ terraform apply
  # module.sitio["blog"].docker_container.this will be created
  # module.sitio["blog"].docker_image.this will be created
  # module.sitio["docs"].docker_container.this will be created
  # module.sitio["docs"].docker_image.this will be created
  # module.sitio["tienda"].docker_container.this will be created
  # module.sitio["tienda"].docker_image.this will be created
Plan: 6 to add, 0 to change, 0 to destroy.
```

Revisor (Juan Jose): «Workspace `staging`, 3 sitios con nginx 1.28. Aprobado: 6 a crear, 0 a cambiar, 0 a destruir».

```text
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

urls = {
  "blog-g1-staging" = "http://localhost:8202"
  "docs-g1-staging" = "http://localhost:8203"
  "tienda-g1-staging" = "http://localhost:8201"
}
```

```text
$ terraform workspace new prod
Created and switched to workspace "prod"!

$ terraform apply
  # module.sitio["blog"].docker_container.this will be created
  # module.sitio["blog"].docker_image.this will be created
  # module.sitio["docs"].docker_container.this will be created
  # module.sitio["docs"].docker_image.this will be created
  # module.sitio["tienda"].docker_container.this will be created
  # module.sitio["tienda"].docker_image.this will be created
Plan: 6 to add, 0 to change, 0 to destroy.
```

Revisor (Juan Jose): «Workspace `prod`, 3 sitios con nginx 1.27. Aprobado: 6 a crear, 0 a cambiar, 0 a destruir».

```text
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

urls = {
  "blog-g1-prod" = "http://localhost:8302"
  "docs-g1-prod" = "http://localhost:8303"
  "tienda-g1-prod" = "http://localhost:8301"
}

$ terraform workspace list
  default
  dev
* prod
  staging
```

Verificación:

```text
$ for p in 8101 8201 8202 8203 8301 8302 8303; do echo "$p: $(curl -s localhost:$p | head -1)"; done
8101: <h1>Tienda - DEV - grupo 1</h1>
8201: <h1>Tienda - STAGING - grupo 1</h1>
8202: <h1>Blog - STAGING - grupo 1</h1>
8203: <h1>Docs - STAGING - grupo 1</h1>
8301: <h1>Tienda - PROD - grupo 1</h1>
8302: <h1>Blog - PROD - grupo 1</h1>
8303: <h1>Docs - PROD - grupo 1</h1>

$ docker exec tf-state-g1 psql -U terraform -d terraform_backend -c "SELECT id, name FROM terraform_remote_state.states;"
 id |  name
----+---------
  1 | default
  4 | dev
  6 | staging
  8 | prod
(4 rows)

$ docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}'
NAMES               IMAGE                PORTS
tienda-g1-prod      65645c7bb6a0         0.0.0.0:8301->80/tcp
blog-g1-prod        65645c7bb6a0         0.0.0.0:8302->80/tcp
docs-g1-prod        65645c7bb6a0         0.0.0.0:8303->80/tcp
tienda-g1-staging   a8b39bd9cf0f         0.0.0.0:8201->80/tcp
blog-g1-staging     a8b39bd9cf0f         0.0.0.0:8202->80/tcp
docs-g1-staging     a8b39bd9cf0f         0.0.0.0:8203->80/tcp
tienda-g1-dev       a8b39bd9cf0f         0.0.0.0:8101->80/tcp
tf-state-g1         postgres:17-alpine   0.0.0.0:5433->5432/tcp
```

El `65645c7bb6a0` es la 1.27 y el `a8b39bd9cf0f` es la 1.28 (los mismos ids que vimos en las fases 2 y 3).

Capturas: [dev 8101](evidencias/fase7-tienda-dev-8101.png), [staging 8201](evidencias/fase7-tienda-staging-8201.png), [prod 8301](evidencias/fase7-tienda-prod-8301.png)

La contraseña no está en el repo (`git grep` no encuentra nada y sale con código 1):

```text
$ git grep <contraseña-del-backend>
$ echo $?
1
```

### Respuestas

**1. ¿Qué respondió la terminal 2 en la prueba de bloqueo? ¿Qué problema de trabajo en equipo evita?**

`Error acquiring the state lock` con `Workspace is already locked: default`, y le muestra quién tiene el bloqueo, desde cuándo y con qué versión. Evita que dos personas trabajen al mismo tiempo sobre el mismo state: sin bloqueo podrían pisarse, crear recursos duplicados o dejar el state corrupto o desactualizado.

**2. ¿Dónde quedó la contraseña del backend y por qué no debe estar en `main.tf`?**

Solo en la variable de entorno `PG_CONN_STR` de la terminal donde trabajamos (y obvio dentro del contenedor de Postgres). Si estuviera en `main.tf` quedaría en el historial de Git para siempre, cualquiera con acceso al repo tendría acceso al state (que a su vez puede tener más secretos), y aunque luego se borre del archivo seguiría en los commits viejos. Además así cada persona o ambiente puede usar sus propias credenciales sin cambiar el código.

**3. ¿Qué filas tiene ahora la tabla `states` y cómo se relacionan con los workspaces?**

Tiene 4 filas: `default` (id 1), `dev` (4), `staging` (6) y `prod` (8). Hay una fila por workspace y cada fila guarda el state completo de ese ambiente. La columna `name` es el nombre del workspace, así que cuando hacemos `workspace select prod`, Terraform lee y escribe solo la fila `prod`. Los ids no son seguidos porque la secuencia de Postgres se va consumiendo en otras operaciones, pero eso no afecta.

**4. ¿Qué error da `terraform plan` en el workspace `default` y por qué es útil que falle?**

`Error: Invalid index`, porque `local.ambientes` no tiene ninguna llave `"default"`. Es útil porque nos obliga a escoger explícitamente un ambiente (dev, staging o prod) antes de desplegar; así nadie aplica por accidente en un ambiente que no existe o sin saber en cuál está.

**5. ¿Por qué dev tiene un solo sitio y staging replica a prod? ¿Por qué prod usa otra versión de imagen?**

Dev es para probar rápido y barato, con un sitio basta para ver si algo funciona. Staging es la réplica de producción, entonces debe tener lo mismo que prod (los tres sitios) para que lo que se pruebe ahí sea confiable antes de lanzar. Prod usa la 1.27 porque la 1.28 todavía se está probando en dev y staging; cuando staging la valide, se cambia la imagen de prod y se promueve.

**6. Los tres ambientes comparten código y backend. ¿Qué riesgo tiene eso frente a usar carpetas separadas por ambiente?**

Que es muy fácil equivocarse de workspace: nada en los archivos dice en qué ambiente estás, entonces un `apply` o `destroy` en el workspace equivocado le puede pegar a prod. También un cambio en el código compartido le llega a todos los ambientes la próxima vez que se apliquen, y como comparten backend y credenciales, el que tiene acceso a dev tiene acceso a prod (y si el backend se cae, se caen los tres). Con carpetas separadas cada ambiente puede tener su propio backend, permisos y versión del módulo, a cambio de repetir algo de código.

---

## Fase 8 · Testing y calidad

### Evidencias

**1. Análisis estático** (desde `infra/`):

```text
$ terraform fmt -check -recursive
$ echo $?
0

$ terraform validate
Success! The configuration is valid.
```

`fmt -check` no reportó nada, así que no hubo que corregir formato. No tenemos `tflint` instalado.

**2. Pruebas del módulo con `terraform test`**

Creamos `infra/modules/sitio_web/tests/sitio_web.tftest.hcl` con las tres pruebas de la guía y la del TODO 1 (`nombre_coincide_con_variable`, con `command = plan`, que verifica `output.nombre == var.nombre`).

```text
$ cd modules/sitio_web
$ terraform init
- Installed kreuzwerker/docker v4.6.0 (self-signed, key ID 0DCE698927DAF8EC)
Terraform has been successfully initialized!

$ terraform test
tests\sitio_web.tftest.hcl... in progress
  run "url_coherente_con_puerto"... pass
  run "rechaza_puerto_fuera_de_rango"... pass
  run "despliegue_real"... pass
  run "nombre_coincide_con_variable"... pass
tests\sitio_web.tftest.hcl... tearing down
tests\sitio_web.tftest.hcl... pass

Success! 4 passed, 0 failed.
```

Lo que vio quien estaba mirando `docker ps` en la otra terminal mientras corría:

```text
$ docker ps --filter name=prueba --format '{{.Names}} {{.Status}} {{.Ports}}'
prueba-g1 Up Less than a second 0.0.0.0:8999->80/tcp
```

Y al terminar:

```text
$ docker ps -a --filter name=prueba
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

El `init` del módulo generó también un `.terraform.lock.hcl` dentro de `modules/sitio_web/`. Lo versionamos igual que el de la raíz porque `validar.sh` corre `terraform test` en esa carpeta y así queda fija la versión del provider.

**3. Escaneo de seguridad** con checkov 3.4.3 (lo instalamos con `pip install checkov`) sobre `seguridad/bucket.tf`.

Primer escaneo (bucket con los cuatro valores en `false`):

```text
$ checkov -d seguridad
Passed checks: 4, Failed checks: 11, Skipped checks: 0

FAILED  CKV_AWS_53   aws_s3_bucket_public_access_block.evidencias  Ensure S3 bucket has block public ACLS enabled
FAILED  CKV_AWS_54   aws_s3_bucket_public_access_block.evidencias  Ensure S3 bucket has block public policy enabled
FAILED  CKV_AWS_55   aws_s3_bucket_public_access_block.evidencias  Ensure S3 bucket has ignore public ACLs enabled
FAILED  CKV_AWS_56   aws_s3_bucket_public_access_block.evidencias  Ensure S3 bucket has 'restrict_public_buckets' enabled
FAILED  CKV2_AWS_6   aws_s3_bucket.evidencias                      Ensure that S3 bucket has a Public Access block
FAILED  CKV2_AWS_62  aws_s3_bucket.evidencias                      Ensure S3 buckets should have event notifications enabled
FAILED  CKV_AWS_144  aws_s3_bucket.evidencias                      Ensure that S3 bucket has cross-region replication enabled
FAILED  CKV_AWS_145  aws_s3_bucket.evidencias                      Ensure that S3 buckets are encrypted with KMS by default
FAILED  CKV2_AWS_61  aws_s3_bucket.evidencias                      Ensure that an S3 bucket has a lifecycle configuration
FAILED  CKV_AWS_18   aws_s3_bucket.evidencias                      Ensure the S3 bucket has access logging enabled
FAILED  CKV_AWS_21   aws_s3_bucket.evidencias                      Ensure all data stored in the S3 bucket have versioning enabled

PASSED  CKV_AWS_93, CKV_AWS_20, CKV_AWS_57, CKV_AWS_19
```

Cambiamos los cuatro valores a `true` y escaneamos otra vez:

```text
$ checkov -d seguridad
Passed checks: 9, Failed checks: 6, Skipped checks: 0

FAILED  CKV2_AWS_62  aws_s3_bucket.evidencias  Ensure S3 buckets should have event notifications enabled
FAILED  CKV2_AWS_61  aws_s3_bucket.evidencias  Ensure that an S3 bucket has a lifecycle configuration
FAILED  CKV_AWS_144  aws_s3_bucket.evidencias  Ensure that S3 bucket has cross-region replication enabled
FAILED  CKV_AWS_18   aws_s3_bucket.evidencias  Ensure the S3 bucket has access logging enabled
FAILED  CKV_AWS_145  aws_s3_bucket.evidencias  Ensure that S3 buckets are encrypted with KMS by default
FAILED  CKV_AWS_21   aws_s3_bucket.evidencias  Ensure all data stored in the S3 bucket have versioning enabled
```

Bajó de 11 a 6, no a cero: quedan versionado, logs de acceso, cifrado con KMS, replicación, ciclo de vida y notificaciones.

**4. El mini pipeline** `validar.sh` en la raíz, con los TODO resueltos:

- TODO 2: `terraform -chdir=infra/modules/sitio_web test`
- TODO 3: `checkov -d seguridad --check CKV_AWS_53,CKV_AWS_54,CKV_AWS_55,CKV_AWS_56`

Corrida normal:

```text
$ bash validar.sh
Success! The configuration is valid.

tests\sitio_web.tftest.hcl... in progress
  run "url_coherente_con_puerto"... pass
  run "rechaza_puerto_fuera_de_rango"... pass
  run "despliegue_real"... pass
  run "nombre_coincide_con_variable"... pass
tests\sitio_web.tftest.hcl... tearing down
tests\sitio_web.tftest.hcl... pass

Success! 4 passed, 0 failed.

terraform scan results:

Passed checks: 4, Failed checks: 0, Skipped checks: 0

Check: CKV_AWS_53: "Ensure S3 bucket has block public ACLS enabled"
	PASSED for resource: aws_s3_bucket_public_access_block.evidencias
Check: CKV_AWS_54: "Ensure S3 bucket has block public policy enabled"
	PASSED for resource: aws_s3_bucket_public_access_block.evidencias
Check: CKV_AWS_55: "Ensure S3 bucket has ignore public ACLs enabled"
	PASSED for resource: aws_s3_bucket_public_access_block.evidencias
Check: CKV_AWS_56: "Ensure S3 bucket has 'restrict_public_buckets' enabled"
	PASSED for resource: aws_s3_bucket_public_access_block.evidencias
Validación completa: el cambio puede pasar a revisión
```

Prueba 1: desordenamos la indentación de `infra/data.tf` a propósito:

```text
data "docker_network" "bridge" {
        name    =    "bridge"
}
```

```text
$ bash validar.sh
data.tf
$ echo $?
3
```

Se detuvo en el primer paso (`fmt -check`), que imprime el archivo mal formateado y sale con error; por el `set -e` no siguió con nada más. Después dejamos el archivo como estaba.

Prueba 2: volvimos a poner `block_public_policy = false` en el bucket:

```text
$ bash validar.sh
...
Success! 4 passed, 0 failed.
...
Check: CKV_AWS_54: "Ensure S3 bucket has block public policy enabled"
	FAILED for resource: aws_s3_bucket_public_access_block.evidencias
	File: \bucket.tf:5-11

		5  | resource "aws_s3_bucket_public_access_block" "evidencias" {
		6  |   bucket                  = aws_s3_bucket.evidencias.id
		7  |   block_public_acls       = true
		8  |   block_public_policy     = false
		9  |   ignore_public_acls      = true
		10 |   restrict_public_buckets = true
		11 | }

$ echo $?
1
```

Esta vez pasó formato, validación y pruebas, y se detuvo en el último paso (checkov), así que nunca imprimió el mensaje final. Lo dejamos otra vez en `true`.

El reto opcional de GitHub Actions no lo hicimos.

**Paso adicional: `.gitattributes`.** En Windows Git convierte los finales de línea a CRLF al hacer checkout, y con CRLF `bash validar.sh` revienta (bash lee la línea `set -e` con un retorno de carro pegado al final y no la entiende) y `fmt -check` podría marcar los `.tf` como mal formateados. Para que el repo funcione igual en el computador de cualquiera de nosotros o del grupo que nos audite, agregamos en la raíz un `.gitattributes` con `* text=auto eol=lf` (y `*.png binary` para las capturas). No estaba en la guía; lo hicimos para que el pipeline no dependa del sistema operativo de quien clone.

### Respuestas

**1. ¿Qué encontró cada nivel (estático, pruebas, seguridad) que los otros no podían encontrar?**

El estático (`fmt` y `validate`) encuentra problemas de forma y sintaxis sin ejecutar nada: la indentación rota del `data.tf` la atrapó `fmt`, y ni las pruebas ni checkov se fijan en eso. Las pruebas revisan que el módulo haga lo que debe: que la URL salga con el puerto correcto, que la validación rechace el 9500, que el output `nombre` sea el de la variable y que de verdad se cree un contenedor con el nombre esperado; eso el análisis estático no lo puede saber porque hay que evaluar el plan o desplegar. Y el escaneo de seguridad encontró el bucket público, que es código perfectamente válido y que pasaría todas las pruebas, pero es una mala configuración peligrosa.

**2. ¿Qué vio quien observaba `docker ps` durante `despliegue_real`? ¿Por qué vale la pena un entorno desechable?**

Vio aparecer un contenedor `prueba-g1` en el puerto 8999, corriendo unos segundos, y luego desaparecer solo cuando `terraform test` hizo el "tearing down". Vale la pena porque probamos con infraestructura real sin tocar dev, staging ni prod, y como se crea y se destruye solo, no deja basura ni (en la nube) costos de recursos olvidados.

**3. ¿Qué controles fallaron en el bucket y cuántos quedaron después de corregir? ¿Cuáles corresponden al ejemplo «sin buckets públicos» de la clase?**

Al principio fallaron 11: CKV_AWS_53, 54, 55, 56, CKV2_AWS_6, CKV2_AWS_62, CKV_AWS_144, CKV_AWS_145, CKV2_AWS_61, CKV_AWS_18 y CKV_AWS_21. Después de poner los cuatro valores en `true` quedaron 6 (versionado, logs de acceso, cifrado con KMS, replicación entre regiones, ciclo de vida y notificaciones). Los de «sin buckets públicos» son CKV_AWS_53 a CKV_AWS_56 (bloquear ACLs públicas, bloquear políticas públicas, ignorar ACLs públicas y restringir buckets públicos), y también CKV2_AWS_6, que pide que el bucket tenga un bloqueo de acceso público bien configurado; esos cinco pasaron con la corrección.

**4. ¿Qué ventaja tiene detectar un problema en el código, antes del `apply`, frente a detectarlo en la nube?**

Que el problema nunca llega a existir. Si el bucket público se crea en la nube, desde ese segundo los datos pueden quedar expuestos (hay bots buscando buckets abiertos todo el tiempo), y después toca arreglarlo en caliente, revisar si alguien accedió y pagar lo que se haya usado. En el código es solo cambiar una línea, el aviso llega en segundos y a la persona que hizo el cambio, y sale gratis.

**5. ¿En qué paso del pipeline de la diapositiva va `validar.sh` y qué paso humano viene después?**

En el paso 2, "Validar", que es justo correr fmt, validate, pruebas y políticas de forma automática después del commit. Después viene el paso 3, "Revisar", donde una persona lee el plan propuesto y lo aprueba (lo que hace nuestro revisor del plan), y solo ahí se pasa al paso 4, aplicar.

---

## Fase 9 · Auditoría cruzada y cierre

### Evidencias

**Parte A · Auditoría**

Pendiente.

**Parte B · Cierre**

Hicimos el cierre antes de la auditoría porque la auditoría se hace sobre el repositorio (código, historial y bitácora) y no necesita la infraestructura arriba.

```text
$ terraform workspace select dev && terraform destroy
  # module.sitio["tienda"].docker_container.this will be destroyed
  # module.sitio["tienda"].docker_image.this will be destroyed
Plan: 0 to add, 0 to change, 2 to destroy.
```

Revisor (Brandon): «Workspace `dev`, se va solo la tienda. Aprobado: 0 a crear, 0 a cambiar, 2 a destruir».

```text
Destroy complete! Resources: 2 destroyed.
```

```text
$ terraform workspace select staging && terraform destroy
  # module.sitio["blog"].docker_container.this will be destroyed
  # module.sitio["blog"].docker_image.this will be destroyed
  # module.sitio["docs"].docker_container.this will be destroyed
  # module.sitio["docs"].docker_image.this will be destroyed
  # module.sitio["tienda"].docker_container.this will be destroyed
  # module.sitio["tienda"].docker_image.this will be destroyed
Plan: 0 to add, 0 to change, 6 to destroy.
```

Revisor (Brandon): «Workspace `staging`, los tres sitios. Aprobado: 0 a crear, 0 a cambiar, 6 a destruir».

```text
Destroy complete! Resources: 6 destroyed.
```

```text
$ terraform workspace select prod && terraform destroy
  # module.sitio["blog"].docker_container.this will be destroyed
  # module.sitio["blog"].docker_image.this will be destroyed
  # module.sitio["docs"].docker_container.this will be destroyed
  # module.sitio["docs"].docker_image.this will be destroyed
  # module.sitio["tienda"].docker_container.this will be destroyed
  # module.sitio["tienda"].docker_image.this will be destroyed
Plan: 0 to add, 0 to change, 6 to destroy.
```

Revisor (Brandon): «Workspace `prod`, los tres sitios. Aprobado: 0 a crear, 0 a cambiar, 6 a destruir».

```text
Destroy complete! Resources: 6 destroyed.

$ terraform workspace select default
Switched to workspace "default".

$ docker ps --format '{{.Names}}'
tf-state-g1
```

Solo quedaba el backend, así que lo eliminamos:

```text
$ docker rm -f tf-state-g1
tf-state-g1
```

Nota sobre las capturas: las primeras que tomamos quedaron muy recortadas, así que las repetimos con la ventana completa del navegador. Para eso volvimos a levantar cada fase con el código exacto de su commit (en una carpeta temporal y con state local), tomamos la captura y la destruimos enseguida. En la Fase 4 repetimos el mismo `docker exec` del experimento C para mostrar el cambio manual.

### Respuestas

**1. ¿Qué anti-patrón encontraron en el otro grupo? ¿Y cuál les señalaron a ustedes?**

Pendiente (después de la auditoría).

**2. ¿Qué habría pasado si eliminaban el contenedor del backend antes de ejecutar los `destroy`?**

Se habría perdido el state de los tres ambientes, porque solo vivía en ese Postgres. Los 7 contenedores seguirían corriendo pero Terraform ya no sabría que existen: un `destroy` diría que no hay nada que destruir y un `apply` intentaría crearlos otra vez y chocaría con los nombres y puertos ocupados. Habría tocado borrarlos a mano con Docker, que es justo lo que queremos evitar, o importarlos uno por uno al state.

**3. ¿Por qué `destroy` exige la misma disciplina de lectura que `apply`?**

Porque también cambia la infraestructura real y no tiene vuelta atrás: lo que se borra (y los datos que tenga) no vuelve. Si no se lee el plan, uno puede estar en el workspace equivocado y tumbar prod creyendo que era dev, o borrar más recursos de los que pensaba. Por eso el revisor confirma en qué workspace estamos y cuántos recursos se van antes de aprobar.
