using KuMo

agent = KuMo.execute()

foreach(_ -> node!(agent, KuMo.Node(75)), 1:4)

link!(agent, 1, 2, KuMo.FreeLink())
link!(agent, 2, 3, KuMo.FreeLink())
link!(agent, 3, 4, KuMo.FreeLink())
link!(agent, 4, 1, KuMo.FreeLink())

foreach(_ -> data!(agent, rand(1:4)), 1:2)
foreach(_ -> user!(agent, rand(1:4)), 1:2)

job!(agent, 0, 1, 1, 0, 1, 1, 0.01)

sleep(10)

stop!(agent)

println(agent.results)
