using Distributions: Normal, Uniform, pdf
using PyPlot
include("MCMC.jl")
include("SMCSampler.jl")
default_f(x) = x
path = "/Users/iamrk/Documents/uni/stat 440/Final_Project/"

# colors for the graph
tableau20 = [(31, 119, 180), (174, 199, 232), (255, 127, 14), (255, 187, 120),
             (44, 160, 44), (152, 223, 138), (214, 39, 40), (255, 152, 150),
             (148, 103, 189), (197, 176, 213), (140, 86, 75), (196, 156, 148),
             (227, 119, 194), (247, 182, 210), (127, 127, 127), (199, 199, 199),
             (188, 189, 34), (219, 219, 141), (23, 190, 207), (158, 218, 229)]
cols = Tuple[]
for i = 1:20
  push!(cols, (tableau20[i][1]/255.0, tableau20[i][2]/255.0, tableau20[i][3]/255.0));
end
cols
function stabalise(x::Array, target::Float64, range=0.01)
  n = length(x);
  first = 0;
  for i = n:-1:1
    if abs(x[i] - target)/target > range
      first = i;
      break;
    end
  end
  return(first)
end
function fm(x::Array, f=default_f)
  result = zeros(Float64, length(x));
  n = length(x);
  result[1] = f(x[1]);
  for i = 2:n
    result[i] = (i-1)/i*result[i-1] + f(x[i, :])/i;
  end
  result
end
function means(x, functions = [g])
  s = zeros(Float64, length(x), length(functions));
  for (i, fun) in enumerate(functions)
    s[:, i] = fm(x, fun);
  end
  return(s)
end



function coll_mat(x, amount = 100)
  m,n = size(x);
  d = int(m/amount)
  collapse = zeros(Float64, d, n);
  for i = 1:d
    collapse[i,:] = mean(x[(i-1)*amount + 1: (i)*amount, :], 1)
  end
  return collapse
end


function exper(sampler:: Function, iters:: Int64, particles:: Int64, function_list, true_values; seed = 0, col_amount = 100)
  running_stats = zeros(n, length(function_list));
  errors = zeros(iters, int(n/col_amount), length(function_list));
  stable = zeros(iters, length(function_list));
  for i = 1:iters
    srand(seed + i);
    x = sampler(particles);
    running_stats = means(x, function_list);
    errors[i, :, :] = coll_mat(abs(broadcast(-, running_stats, true_values')), col_amount);
    for (j, val) in enumerate(true_values)
      stable[i, j] = stabalise(running_stats[:,j], val, 0.02)
    end
  end
  return stable, errors
end

p(x, alpha = 1.0) = (exp(-(x - 2).^2/2) +
                       0.5*exp(-(x+2).^2/1) +
                       0.5*exp(-(x-5).^2/1) +
                       0.5*exp(-(x-15).^2/1)).^(alpha).*exp(-(x).^2/2).^(1-alpha);

# made up
e_x = 8.11687;
e_x2 = 66.5233;
true_values = [e_x; e_x2];

# Experiments
n = int(1e6); #number of samples
g(x) = x.^2; f(x) = x; function_list = [f, g];
n_experiments = 50;
d = 5;
mcmc_sampler(n) = mcmc(p, rand(), n = n, stype = Float32, sig = 15);
smc_sampler(n) = reshape(smcsampler(p, N=n, p = d, σ = 15.0)[d, :], n);

tic()
mcmc_stab, mcmc_errs = exper(mcmc_sampler, n_experiments, n, function_list, true_values, col_amount = 1);
mcmc_walltime = toc();
mcmc_time = [i * mcmc_walltime/n/n_experiments for i in 1:n]
size(mcmc_errs)
mcmc_er_mean = reshape(mean(mcmc_errs, 1), n, 2)
mcmc_er_sd = reshape(std(mcmc_errs, 1), n, 2)

tic()
smc_stab, smc_errs = exper(smc_sampler, n_experiments, n, function_list, true_values, col_amount = 1);
smc_walltime = toc();
size(smc_errs)
smc_time = [i * smc_walltime/n/n_experiments for i in 1:n]
smc_er_mean = reshape(mean(smc_errs, 1), n, 2)
smc_er_sd = reshape(std(smc_errs, 1), n, 2)


# Plot figures
fig_x = 9;
fig_y = 5;

plt.figure(1, figsize=(fig_x,fig_y));
plt.clf();
plt.yscale("log");
plt_smc = plt.plot(1:n, smc_er_mean[:,1], color = cols[1]);
plt_mcmc = plt.plot(1:n, mcmc_er_mean[:,1], color = cols[4]);
plt.title(L"Mean absolute error of $E[x]$", family = "serif");
plt.ylabel("Mean error", family = "serif");
plt.xlabel("Number of Particles", family = "serif");
plt.legend([plt_smc, plt_mcmc], ["SMC Sampler", "MCMC"], frameon = false, prop={"size"=>12, "family"=>"serif"})
savefig("$path/E_X.png")
savefig("$path/E_X.pdf")

plt.figure(1, figsize=(fig_x,fig_y));
plt.clf();
plt.yscale("log");
plt_smc = plt.plot(smc_time, smc_er_mean[:,1], color = cols[1]);
plt_mcmc = plt.plot(mcmc_time, mcmc_er_mean[:,1], color = cols[4]);
plt.title(L"Mean absolute error of $E[x]$", family = "serif");
plt.ylabel("Mean error", family = "serif");
plt.xlabel("Average Walltime (s)", family = "serif");
plt.legend([plt_smc, plt_mcmc], ["SMC Sampler", "MCMC"], frameon = false, prop={"size"=>12, "family"=>"serif"})
savefig("$path/E_X_walltime.png")
savefig("$path/E_X_walltime.pdf")

plt.figure(1, figsize=(fig_x,fig_y));
plt.clf();
plt.yscale("log");
plt_smc = plt.plot(1:n, smc_er_sd[:,1], color = cols[1]);
plt_mcmc = plt.plot(1:n, mcmc_er_sd[:,1], color = cols[4]);
plt.title(L"Standard Deviation of absolute error of $E[x]$", family = "serif");
plt.ylabel("Mean error", family = "serif");
plt.xlabel("Number of Particles", family = "serif");
plt.legend([plt_smc, plt_mcmc], ["SMC Sampler", "MCMC"], frameon = false, prop={"size"=>12, "family"=>"serif"})
savefig("$path/sdE_X.png")
savefig("$path/sdE_X.pdf")

plt.figure(1, figsize=(fig_x,fig_y));
plt.clf();
plt.yscale("log");
plt_smc = plt.plot(1:n, smc_er_mean[:,2], color = cols[1]);
plt_mcmc = plt.plot(1:n, mcmc_er_mean[:,2], color = cols[4]);
plt.title(L"Mean absolute error of $E[x^2]$", family = "serif");
plt.ylabel("Mean error", family = "serif");
plt.xlabel("Number of Particles", family = "serif");
plt.legend([plt_smc, plt_mcmc], ["SMC Sampler", "MCMC"], frameon = false, prop={"size"=>12, "family"=>"serif"})
savefig("$path/E_X2.png")
savefig("$path/E_X2.pdf")


e_x = 4.05887;
e_x2 = 46.2633;

srand(1236)
x0 = rand(); #starting position
n = int(1e6); #number of samples



g(x) = x.^2;
diff_x = fm(x);
diff_x2 = fm(x, g);
stable_x = stabalise(diff_x, e_x);

diff_y = fm(y);
diff_y2 = fm(y, g);
stable_y = stabalise(diff_y, e_x);

plt.clf()
plt.plot((1, n), (e_x, e_x), color = cols[19])
plt.plot((1, n), (e_x*1.01, e_x*1.01), color = cols[20])
plt.plot((1, n), (e_x*0.99, e_x*0.99), color = cols[20])
plt.plot((stable_x, stable_x), (0, e_x*20), color = cols[7])
plt.plot((stable_y, stable_y), (0, e_x*20), color = cols[7])
plt_mcmc = plt.plot(1:n, diff_x, color = cols[1])
plt_smc = plt.plot(1:n, diff_y, color = cols[3])
plt.ylim(e_x*0.98, e_x*1.02)
plt.legend([plt_smc, plt_mcmc], ["SMC Sampler", "MCMC"], frameon = false, prop={"size"=>12, "family"=>"serif"})
plt.xlabel("Number iterations", family = "serif");
plt.xlim(0, n)
plt.title(L"Convergence a typical run to $E[x]$")
savefig("$path/Convergence.png")
