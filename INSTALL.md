# 🛠️ Guia de Instalação do NetCable (TrueNAS)

> 🏠 **DietPi / Raspberry Pi?** Veja `install/dietpi/` — instalação nativa
> (sem Docker) com `install/dietpi/install.sh`. Detalhes no fim deste arquivo.

Este guia explica como instalar o NetCable no seu servidor TrueNAS usando Docker. O sistema irá rodar de forma isolada e salvar os dados (banco de dados) localmente no seu servidor.

## 📋 Pré-requisitos
- TrueNAS SCALE (versão com suporte a Apps/Docker).
- Acesso via Shell (SSH ou painel web).
- Um dataset (pasta) no seu pool para armazenar os dados.

## 🛠️ Passo 1: Criar a pasta de dados
No terminal do TrueNAS, crie a pasta onde o banco de dados será salvo (substitua `ssd-apps/vm` pelo caminho do seu pool):
```bash
mkdir -p /mnt/ssd-apps/vm/netcable
chmod 777 /mnt/ssd-apps/vm/netcable

📝 2: O Arquivo YAML

Vá em Apps > Discover Apps > Custom App > Install via YAML.

Cole o conteúdo do arquivo install/trueNAS.yml (que está no repositório).

⚠️ IMPORTANTE: Antes de instalar, edite o YAML e altere:

ADMIN_USER: O nome de usuário que você quer usar.

ADMIN_PASSWORD: A sua senha (evite #, pois o YAML pode cortar).

O caminho do volume (/mnt/SEU_POOL/...) para o local onde você criou a pasta no Passo 1.

Clique em Install.

🌐 Passo 3: Acessar
Frontend: http://IP_DO_TRUENAS:3080

API (Documentação): http://IP_DO_TRUENAS:8000/docs

🔄 Como atualizar
Sempre que houver uma atualização no código, o GitHub Actions constrói uma nova imagem. No TrueNAS, basta ir em Apps e clicar em Update no app netcable.

🖥️ Notas sobre o Monitoramento
Linux/Switches: Funcionam de primeira (ping/TCP).

Windows: Pode precisar liberar o ICMP (ping) no Firewall do Windows.

Switches "Burros": Cadastre como "Sem IP" (visual).

Documento gerado e mantido pela equipe NetCable.

---

## 🏠 Instalação no DietPi (Raspberry Pi 1 / ARMv6, sem Docker)

As imagens GHCR são amd64-only e o Pi 1 não roda Docker de forma útil,
então a instalação é nativa: backend Python (systemd) + frontend estático
(nginx). Arquivos em `install/dietpi/`.

**No Pi (usuário `dietpi`):**
```bash
bash ~/netcable/install.sh
```

O que o script faz:
1. Instala nginx, venv e ferramentas de compilação via APT.
2. Cria `/home/dietpi/netcable/venv` e instala
   `install/dietpi/requirements-dietpi.txt`.
3. Gera `/home/dietpi/netcable/.env` com `ADMIN_USER`/`ADMIN_PASSWORD`.
4. Ativa o serviço `netcable-backend` (uvicorn em `127.0.0.1:8000`).
5. Serve o frontend na porta **3080** com proxy de `/api/` para o backend.

**Acesso:** `http://IP_DO_PI:3080` (senha em `/home/dietpi/netcable/.env`).
**Banco SQLite:** `/home/dietpi/netcable/backend/data/netcable.db`.

**Por que as versões são pinadas** (`requirements-dietpi.txt`):
- `fastapi==0.95.1` + `pydantic==1.10.20` — o pydantic v2 (pydantic-core,
  Rust) não tem wheel para ARMv6; a 1.10.20 usa wheel puro-Python.
- `bcrypt==3.2.2` — a 4.x exige Rust; a 3.2.x compila com gcc e funciona
  com o passlib usado em `backend/app/main.py`.