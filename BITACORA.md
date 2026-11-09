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
