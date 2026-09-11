---
title: [译] AI 与自我提升的相似之处
summary: 写下来、跟自己对话、扮演另一个角色：AI 智能体与自我提升的相似之处。
---

在 [The Agentic Self: Parallels Between AI and Self-Improvement](https://muratbuffalo.blogspot.com/2026/01/the-agentic-self-parallels-between-ai.html) 中，作者 Murat Demirbas 通过审视 AI 智能体和智能系统的实现架构，分析探讨了三个（writing things down、talking to yourself 和 pretending to be someone else）关于自我提升的建议，以及 AI 与其相似之处。

* * *

2025 年是智能体（_Agent_）的元年。通用人工智能的目标悄然转移，我们不再满足于让 AI 会“说话”，而是要求它会“行动”。作为旁观者审视这些新兴智能体与智能系统的架构时，我注意到一些奇妙的现象：让 AI 变聪明的工程技巧竟有种莫名的熟悉感。与其说是计算机科学，不如说更像是……自我提升的建议。

智能体智能的秘密似乎藏在三个极其简单的人类习惯里：**把事情写下来**、**跟自己对话**、**假装成别人**。简单得令人难以置信。

## 写作具有的不可思议的有效性

读博期间，我读过的最深刻建议来自图灵奖得主曼纽尔·布卢姆（_Manuel Blum_）教授。他在《[致初入学门的研究生](https://www.cs.cmu.edu/~mblum/research/pdf/grad.html)》一文中写道：**“没有写作，你就退化成有限状态自动机；有了写作，你便拥有图灵机的非凡力量。”**（_Without writing, you are reduced to a finite automaton. With writing you have the extraordinary power of a Turing machine._）

如果你试图在脑中装下整个复杂论证，必定会失败。你的工作记忆是个“有限状态自动机”，容量极其有限。但当你把事情写下来，就把记忆卸载给了纸张。你可以随时查阅、批判，并在此基础上继续构建。纸张成了你的外置硬盘。

AI 智能体正是基于这一原理构建的。大语言模型（_LLM_）的上下文窗口（_Context Window_）有限，有效注意力时长受限。若试图一次性解决 50 步的编程问题，必定崩溃惨败。为此，我们给智能体配备草稿纸，要求在执行代码前必须先写下计划，提供记忆缓冲区来存储后续需要的线索。本质上就是要求 AI 做笔记。通过将内部状态外化到数字纸张上，智能体从简单的模式匹配器进化为稳健的推理者。

## 思考就是不停地跟自己说话

长期以来，我们把大语言模型当作简单的输入/输出机器：我们提出一个问题，它给出一个答案。结果常常令人失望，答案可能是幻觉或肤浅的。DeepSeek 改变了这一点，让模型在回答前先进行“思考”。但思考对计算机意味着什么？意味着生成用户看不见的文字：内心独白。这种意义上，它与人类思维如出一辙。

**写作是让你看清思维多么混乱的自然方式。(Writing is nature's way of letting you know how sloppy your thinking is.)** — 迪克·金登（[Dick Guindon](https://en.wikipedia.org/wiki/Dick_Guindon)）

**如果你不动笔思考，你只是在假装思考而已。(If you think without writing, you only think you're thinking.)** — 莱斯利·兰伯特（[Leslie Lamport](https://en.wikipedia.org/wiki/Leslie_Lamport)）

这又回到了写作具有的不可思议的有效性，只是这次在 [OODA 循环](https://en.wikipedia.org/wiki/OODA_loop)（Observe, Orient, Decide, Act Loop）中执行。思考不是瞬间完成的，它是一个过程，原型迭代才是王道。智能体遵循这样一个循环：**写下 → 分析/推理 → 重复**。它与自己对话，将复杂问题拆解成可管理的部分。它会问“等一下，我是否应该检验这个假设？”或者“这看起来不对，让我再试一次”。

## 角色扮演：第二自我效应

几年前我读过《[The Alter Ego Effect: The Power of Secret Identities to Transform Your Life](https://book.douban.com/subject/33142947/)》。核心思想是，采用某种人格可以释放隐藏的能力。通过进入特定角色，你绕过了自身的限制，触发一套明确的行为。碧昂丝（Beyoncé）在舞台上拥有“萨莎·菲尔斯”，大多数运动员都有他们的“比赛状态”。这本书论证充分，但当时我觉得太俗气，甚至没写一篇博客提及。

没想到这套方法真的管用。在 AI 智能体世界，这被称为“角色提示”或“多智能体系统”。

如果你让单个 AI “写代码”，结果可能平庸。但如果你分配一个 AI 扮演“架构师”来规划代码，另一个扮演“工程师”来编写，第三个扮演“批评者”来审查，结果会指数级提升。

这些角色不只是戏剧化，它们是归纳偏置（[Inductive bias](https://en.wikipedia.org/wiki/Inductive_bias)），约束了搜索空间（[Search space](https://en.wikipedia.org/wiki/Search_space)）。正如采用“严格编辑”的人格能帮助作家删减冗余，给 AI 分配“调试器”角色会迫使它寻找错误，而非单纯生成文字。

顾问模型（Advisor Models）则是元思考者，不直接执行任务，而是监控其他智能体、标记风险和指导决策。在编程中，顾问可能会警告架构师某项设计的风险，或提示工程师避开容易出错的代码。通过提供这种高层监督，顾问让智能体专注于即时任务，同时保持长远目标处于视野中，使多智能体系统更具战略性。

这难道不是经典建议专栏的陈词滥调：“找个教练帮忙（get a coach）”？

## 未来走向何方？

也许我们正逐渐意识到，要发挥那种“基于模式匹配”的原生智能，最有效的路径其实是一套极简的通用工作法：**写下来、讲清楚（或试一把）、检查你的工作**。这些步骤可能提供了支撑推理的“最小脚手架”，构成了思维的核心机制。

兰伯特给金登的推论：**数学自然地揭示了我们写作有多粗糙。(Mathematics is nature's way of showing how sloppy our writing is.)**

数学消除了文字表达中那些语焉不详的漏洞。写作对思维的作用，正如数学对写作的作用。这很可能就是“符号化 AI”和“形式化方法”变得重要的地方。仅仅是写出一份规格说明，就已经在磨砺思维了；而将其进一步“形式化”，则是对思维的二次精炼，从而让逻辑推理达到极致的精准与可靠。
