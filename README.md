# Pirapong

O app da mesa de tênis de mesa: a **fila** do dia a dia e os **torneios**.

No ar em **[www.pirapong.com.br](https://www.pirapong.com.br)**.

## Fila

Formato *vencedor fica na mesa*. Quem chega põe o nome pelo celular. Os dois primeiros entram; ao fim da partida alguém marca quem venceu. O perdedor volta pro fim da fila, e o vencedor fica — **no máximo duas partidas seguidas**, depois cede o lugar mesmo ganhando. Todos os aparelhos abertos atualizam na hora.

## Torneio

Grupos e depois mata-mata. As inscrições ficam abertas a qualquer um; na hora do sorteio o app distribui os inscritos em grupos de 3 a 5, todos se enfrentam dentro do grupo e **passam os 2 primeiros**. Daí monta a chave eliminatória até o campeão.

O desempate dentro do grupo é pela mini-tabela — só os jogos entre os empatados. Quando nem isso resolve (o clássico ciclo de três), o app avisa em vez de inventar uma ordem.

Quem organiza entra com o Google e é o único que sorteia e lança resultados. Para se inscrever ou acompanhar, ninguém precisa de conta.

## Estrutura

```
index.html          o app inteiro (HTML + CSS + JS, sem build)
supabase/
  schema.sql        a fila
  torneio.sql       torneios, inscrições, partidas, RLS e realtime
CLAUDE.md           contexto e convenções para o Claude Code
```

## Rodar

Não tem build nem dependências. Abra o `index.html` no navegador — só precisa de internet para o banco responder.

## Publicar

O Cloudflare Pages está conectado a este repositório: **`git push` na `main` publica**.

## Stack

HTML/CSS/JS puro · [Supabase](https://supabase.com) (Postgres, Auth e Realtime) · Cloudflare Pages
